import java.io.IOException;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import org.eventb.core.ast.ASTProblem;
import org.eventb.core.ast.Assignment;
import org.eventb.core.ast.AssociativeExpression;
import org.eventb.core.ast.AssociativePredicate;
import org.eventb.core.ast.BecomesEqualTo;
import org.eventb.core.ast.BinaryExpression;
import org.eventb.core.ast.BinaryPredicate;
import org.eventb.core.ast.BoolExpression;
import org.eventb.core.ast.BoundIdentDecl;
import org.eventb.core.ast.BoundIdentifier;
import org.eventb.core.ast.Expression;
import org.eventb.core.ast.Formula;
import org.eventb.core.ast.FormulaFactory;
import org.eventb.core.ast.FreeIdentifier;
import org.eventb.core.ast.GivenType;
import org.eventb.core.ast.IParseResult;
import org.eventb.core.ast.ITypeCheckResult;
import org.eventb.core.ast.ITypeEnvironmentBuilder;
import org.eventb.core.ast.IntegerLiteral;
import org.eventb.core.ast.MultiplePredicate;
import org.eventb.core.ast.PowerSetType;
import org.eventb.core.ast.Predicate;
import org.eventb.core.ast.ProductType;
import org.eventb.core.ast.QuantifiedExpression;
import org.eventb.core.ast.QuantifiedPredicate;
import org.eventb.core.ast.RelationalPredicate;
import org.eventb.core.ast.SetExtension;
import org.eventb.core.ast.SimplePredicate;
import org.eventb.core.ast.Type;
import org.eventb.core.ast.UnaryExpression;
import org.eventb.core.ast.UnaryPredicate;

/**
 * Checks Event-B components written in the CamilleX notation with the Rodin formula library.
 *
 * <p>The checker reads contexts ({@code .bucx}) and machines ({@code .bumx}), and checks them the way the static
 * checker of Rodin does: the carrier sets of a context and the contexts it extends are given sets; every axiom,
 * invariant and action is parsed and type-checked in order, and the types inferred for constants and variables are
 * added to the type environment for the formulas that follow. A formula that does not parse or type-check, an
 * identifier that is not declared, a constant or variable left without a type, a duplicate name or label, and an
 * initialisation that does not assign every variable exactly once, or that reads a variable, are errors.
 *
 * <p>With {@code --evaluate machine}, the checker also evaluates a machine whose constants are all fixed by its
 * contexts and whose initialisation is deterministic: it computes the values of the constants from the axioms of
 * the form {@code c = e} and {@code partition(S, {a}, ...)}, checks every axiom on those values, runs the
 * initialisation and reports for each invariant whether it holds. The objects and other constants that partitions
 * fix are distinct atoms; carrier sets that no partition fixes are not enumerated.
 *
 * <p>Usage: {@code java -Djava.awt.headless=true -cp <rodin-ast.jar>:<classes> EventBChecker [--evaluate <machine>]
 * <file>...}. The checker prints one line per checked component and per evaluated formula, reports problems as lines
 * starting with {@code error:}, and exits with status 1 if there are any.
 */
public final class EventBChecker {
    /** The formula factory of the default Event-B mathematical language. */
    private static final FormulaFactory FACTORY = FormulaFactory.getDefault();

    /** The words that start or end a clause of a component; a formula ends before any of them. */
    private static final Set<String> KEYWORDS = Set.of(
        "context", "extends", "sets", "constants", "axioms", "theorem", "end", "machine", "refines", "sees",
        "variables", "invariants", "variant", "events", "event", "any", "where", "when", "with", "then", "begin",
        "ordinary", "convergent", "anticipated");

    /** The name of the event that initialises a machine. */
    private static final String INITIALISATION = "INITIALISATION";

    /** The problems found so far. */
    private final List<String> errors = new ArrayList<>();

    /** The components read, by name. */
    private final Map<String, Component> components = new LinkedHashMap<>();

    /** The type environments of the checked components, by name. */
    private final Map<String, ITypeEnvironmentBuilder> environments = new HashMap<>();

    /** A labelled formula of a component, with the comment written before it. */
    record Element(String label, String text, String comment, boolean theorem) {}

    /** An event of a machine. */
    record Event(String name, List<Element> guards, List<Element> actions) {}

    /** A context or machine. */
    static final class Component {
        /** Whether the component is a machine. */
        boolean machine;
        /** The name of the component. */
        String name;
        /** The contexts that a context extends or a machine sees. */
        final List<String> parents = new ArrayList<>();
        /** The carrier sets of a context. */
        final List<String> sets = new ArrayList<>();
        /** The constants of a context or the variables of a machine. */
        final List<String> identifiers = new ArrayList<>();
        /** The axioms of a context or the invariants of a machine. */
        final List<Element> formulas = new ArrayList<>();
        /** The events of a machine. */
        final List<Event> events = new ArrayList<>();
    }

    /**
     * Checks the components named on the command line.
     *
     * @param arguments an optional {@code --evaluate machine}, followed by the files to check
     * @throws IOException if a file cannot be read
     */
    public static void main(String[] arguments) throws IOException {
        EventBChecker checker = new EventBChecker();
        String evaluated = null;
        List<String> files = new ArrayList<>(Arrays.asList(arguments));
        if (files.size() >= 2 && files.get(0).equals("--evaluate")) {
            evaluated = files.get(1);
            files = files.subList(2, files.size());
        }
        for (String file : files) {
            checker.read(Path.of(file));
        }
        for (Component component : checker.components.values()) {
            checker.check(component);
        }
        if (evaluated != null && checker.errors.isEmpty()) {
            checker.evaluate(evaluated);
        }
        for (String error : checker.errors) {
            System.out.println("error: " + error);
        }
        System.exit(checker.errors.isEmpty() ? 0 : 1);
    }

    // MARK: Reading the CamilleX notation

    /** A token of the CamilleX notation: a comment string, a label, a word or any other text. */
    record Token(Kind kind, String text, int start, int end) {
        enum Kind { STRING, LABEL, WORD, OTHER }
    }

    /**
     * Reads a component from a file.
     *
     * @param file the file
     * @throws IOException if the file cannot be read
     */
    void read(Path file) throws IOException {
        String source = Files.readString(file, StandardCharsets.UTF_8);
        List<Token> tokens = tokenise(source, file.getFileName().toString());
        Parser parser = new Parser(tokens, source, file.getFileName().toString());
        try {
            Component component = parser.component();
            if (components.containsKey(component.name)) {
                errors.add(component.name + ": the component is defined twice");
            }
            components.put(component.name, component);
        } catch (IllegalStateException problem) {
            errors.add(file.getFileName() + ": " + problem.getMessage());
        }
    }

    /**
     * Splits the text of a component into tokens, dropping white space and comments.
     *
     * @param source the text
     * @param file the name of the file, for messages
     * @return the tokens
     */
    List<Token> tokenise(String source, String file) {
        List<Token> tokens = new ArrayList<>();
        int i = 0;
        while (i < source.length()) {
            char c = source.charAt(i);
            if (Character.isWhitespace(c)) {
                i++;
            } else if (source.startsWith("//", i)) {
                int end = source.indexOf('\n', i);
                i = end < 0 ? source.length() : end;
            } else if (source.startsWith("/*", i)) {
                int end = source.indexOf("*/", i + 2);
                if (end < 0) {
                    errors.add(file + ": unterminated comment");
                    return tokens;
                }
                i = end + 2;
            } else if (c == '"') {
                StringBuilder text = new StringBuilder();
                int j = i + 1;
                while (j < source.length() && source.charAt(j) != '"') {
                    if (source.charAt(j) == '\\' && j + 1 < source.length()) {
                        j++;
                        char escaped = source.charAt(j);
                        text.append(escaped == 'n' ? '\n' : escaped == 't' ? '\t' : escaped);
                    } else {
                        text.append(source.charAt(j));
                    }
                    j++;
                }
                if (j >= source.length()) {
                    errors.add(file + ": unterminated string");
                    return tokens;
                }
                tokens.add(new Token(Token.Kind.STRING, text.toString(), i, j + 1));
                i = j + 1;
            } else if (c == '@') {
                int end = source.indexOf(':', i);
                if (end < 0) {
                    errors.add(file + ": a label has no colon");
                    return tokens;
                }
                tokens.add(new Token(Token.Kind.LABEL, source.substring(i + 1, end).trim(), i, end + 1));
                i = end + 1;
            } else if (isWordCharacter(c)) {
                int j = i;
                while (j < source.length() && isWordCharacter(source.charAt(j))) {
                    j++;
                }
                tokens.add(new Token(Token.Kind.WORD, source.substring(i, j), i, j));
                i = j;
            } else {
                tokens.add(new Token(Token.Kind.OTHER, String.valueOf(c), i, i + 1));
                i++;
            }
        }
        return tokens;
    }

    private static boolean isWordCharacter(char c) {
        return c < 128 && (Character.isLetterOrDigit(c) || c == '_' || c == '\'');
    }

    /** Reads the clauses of one component from its tokens. */
    final class Parser {
        private final List<Token> tokens;
        private final String source;
        private final String file;
        private int position;

        Parser(List<Token> tokens, String source, String file) {
            this.tokens = tokens;
            this.source = source;
            this.file = file;
        }

        private Token peek() {
            return position < tokens.size() ? tokens.get(position) : null;
        }

        private boolean atKeyword(String word) {
            Token token = peek();
            return token != null && token.kind() == Token.Kind.WORD && token.text().equals(word);
        }

        private boolean atClauseEnd() {
            Token token = peek();
            return token == null || (token.kind() == Token.Kind.WORD && KEYWORDS.contains(token.text()));
        }

        private String expectWord() {
            Token token = peek();
            if (token == null || token.kind() != Token.Kind.WORD || KEYWORDS.contains(token.text())) {
                throw new IllegalStateException("a name is expected at " + describe(token));
            }
            position++;
            return token.text();
        }

        private void expect(String word) {
            if (!atKeyword(word)) {
                throw new IllegalStateException("'" + word + "' is expected at " + describe(peek()));
            }
            position++;
        }

        private String describe(Token token) {
            if (token == null) {
                return "the end of " + file;
            }
            int line = 1;
            for (int i = 0; i < token.start(); i++) {
                if (source.charAt(i) == '\n') {
                    line++;
                }
            }
            return "'" + token.text() + "' in line " + line;
        }

        private String comment() {
            Token token = peek();
            if (token != null && token.kind() == Token.Kind.STRING) {
                position++;
                return token.text();
            }
            return null;
        }

        Component component() {
            Component component = new Component();
            comment();
            if (atKeyword("context")) {
                position++;
                component.name = expectWord();
                contextClauses(component);
            } else {
                expect("machine");
                component.machine = true;
                component.name = expectWord();
                machineClauses(component);
            }
            if (atKeyword("end")) {
                position++;
            }
            if (peek() != null) {
                throw new IllegalStateException("unexpected text at " + describe(peek()));
            }
            return component;
        }

        private void contextClauses(Component component) {
            while (peek() != null && !atKeyword("end")) {
                if (atKeyword("extends")) {
                    position++;
                    names(component.parents);
                } else if (atKeyword("sets")) {
                    position++;
                    names(component.sets);
                } else if (atKeyword("constants")) {
                    position++;
                    names(component.identifiers);
                } else if (atKeyword("axioms")) {
                    position++;
                    formulas(component.formulas, false);
                } else if (atKeyword("theorem")) {
                    position++;
                    component.formulas.add(formula(null, true));
                } else {
                    throw new IllegalStateException("a clause is expected at " + describe(peek()));
                }
            }
        }

        private void machineClauses(Component component) {
            while (peek() != null && !atKeyword("end")) {
                if (atKeyword("sees")) {
                    position++;
                    names(component.parents);
                } else if (atKeyword("variables")) {
                    position++;
                    names(component.identifiers);
                } else if (atKeyword("invariants")) {
                    position++;
                    formulas(component.formulas, false);
                } else if (atKeyword("theorem")) {
                    position++;
                    component.formulas.add(formula(null, true));
                } else if (atKeyword("events")) {
                    position++;
                    while (atKeyword("event") || peek() != null && peek().kind() == Token.Kind.STRING) {
                        component.events.add(event());
                    }
                } else if (atKeyword("event") || peek().kind() == Token.Kind.STRING) {
                    component.events.add(event());
                } else {
                    throw new IllegalStateException("a clause is expected at " + describe(peek()));
                }
            }
        }

        private void names(List<String> names) {
            while (!atClauseEnd()) {
                comment();
                names.add(expectWord());
            }
        }

        private void formulas(List<Element> elements, boolean theorem) {
            while (true) {
                int start = position;
                String comment = comment();
                Token token = peek();
                if (token == null || token.kind() != Token.Kind.LABEL) {
                    position = start;
                    return;
                }
                elements.add(formula(comment, theorem));
            }
        }

        private Element formula(String comment, boolean theorem) {
            Token label = peek();
            if (label == null || label.kind() != Token.Kind.LABEL) {
                throw new IllegalStateException("a label is expected at " + describe(label));
            }
            position++;
            int start = label.end();
            int end = start;
            while (peek() != null && peek().kind() != Token.Kind.STRING && peek().kind() != Token.Kind.LABEL
                && !(peek().kind() == Token.Kind.WORD && KEYWORDS.contains(peek().text()))) {
                end = peek().end();
                position++;
            }
            String text = source.substring(start, end).trim();
            if (text.isEmpty()) {
                throw new IllegalStateException("the formula of " + label.text() + " is empty");
            }
            return new Element(label.text(), text, comment, theorem);
        }

        private Event event() {
            comment();
            expect("event");
            String name = expectWord();
            List<Element> guards = new ArrayList<>();
            List<Element> actions = new ArrayList<>();
            if (atKeyword("where") || atKeyword("when")) {
                position++;
                formulas(guards, false);
            }
            if (atKeyword("then") || atKeyword("begin")) {
                position++;
                formulas(actions, false);
            }
            expect("end");
            return new Event(name, guards, actions);
        }
    }

    // MARK: Static checking

    /**
     * Checks a component after the components it depends on, and records its type environment.
     *
     * @param component the component
     * @return the type environment of the component, or null if a component it depends on is missing
     */
    ITypeEnvironmentBuilder check(Component component) {
        ITypeEnvironmentBuilder known = environments.get(component.name);
        if (known != null) {
            return known;
        }
        ITypeEnvironmentBuilder environment = FACTORY.makeTypeEnvironment();
        for (String parent : component.parents) {
            Component context = components.get(parent);
            if (context == null || context.machine) {
                errors.add(component.name + ": the context " + parent + " is not given");
                return null;
            }
            ITypeEnvironmentBuilder inherited = check(context);
            if (inherited == null) {
                return null;
            }
            environment.addAll(inherited);
        }
        Set<String> labels = new HashSet<>();
        for (String set : component.sets) {
            declare(component, environment, set);
            environment.addGivenSet(set);
        }
        Set<String> pending = new LinkedHashSet<>();
        for (String identifier : component.identifiers) {
            declare(component, environment, identifier);
            if (!pending.add(identifier)) {
                errors.add(component.name + ": " + identifier + " is declared twice");
            }
        }
        for (Element element : component.formulas) {
            if (!labels.add(element.label())) {
                errors.add(component.name + ": the label " + element.label() + " is used twice");
            }
            IParseResult parsed = FACTORY.parsePredicate(element.text(), null);
            if (report(component, element, parsed.getProblems())) {
                continue;
            }
            Predicate predicate = parsed.getParsedPredicate();
            ITypeCheckResult result = predicate.typeCheck(environment);
            if (report(component, element, result.getProblems())) {
                continue;
            }
            for (String name : result.getInferredEnvironment().getNames()) {
                if (!pending.remove(name)) {
                    errors.add(component.name + " " + element.label() + ": " + name + " is not declared");
                }
            }
            environment.addAll(result.getInferredEnvironment());
        }
        for (String name : pending) {
            errors.add(component.name + ": " + name + " has no type");
        }
        int actions = 0;
        for (Event event : component.events) {
            actions += checkEvent(component, environment, event);
        }
        if (component.machine && component.events.stream().noneMatch(e -> e.name().equals(INITIALISATION))) {
            errors.add(component.name + ": the machine has no " + INITIALISATION);
        }
        System.out.println("checked " + (component.machine ? "machine " : "context ") + component.name + ": "
            + component.sets.size() + " sets, " + component.identifiers.size()
            + (component.machine ? " variables, " : " constants, ") + component.formulas.size()
            + (component.machine ? " invariants, " : " axioms, ") + actions + " actions");
        environments.put(component.name, environment);
        return environment;
    }

    private void declare(Component component, ITypeEnvironmentBuilder environment, String name) {
        IParseResult parsed = FACTORY.parseExpression(name, null);
        if (parsed.hasProblem() || parsed.getParsedExpression().getTag() != Formula.FREE_IDENT) {
            errors.add(component.name + ": " + name + " is not a valid identifier");
        } else if (environment.contains(name)) {
            errors.add(component.name + ": " + name + " is already declared");
        }
    }

    private boolean report(Component component, Element element, List<ASTProblem> problems) {
        boolean failed = false;
        for (ASTProblem problem : problems) {
            if (problem.isError()) {
                errors.add(component.name + " " + element.label() + ": " + problem + " in: " + element.text());
                failed = true;
            }
        }
        return failed;
    }

    private int checkEvent(Component component, ITypeEnvironmentBuilder environment, Event event) {
        if (!event.name().equals(INITIALISATION) || !event.guards().isEmpty()) {
            errors.add(component.name + ": only an " + INITIALISATION + " without guards is expected, not "
                + event.name());
            return 0;
        }
        Set<String> variables = new HashSet<>(component.identifiers);
        Set<String> assigned = new HashSet<>();
        Set<String> labels = new HashSet<>();
        for (Element action : event.actions()) {
            if (!labels.add(action.label())) {
                errors.add(component.name + ": the action label " + action.label() + " is used twice");
            }
            IParseResult parsed = FACTORY.parseAssignment(action.text(), null);
            if (report(component, action, parsed.getProblems())) {
                continue;
            }
            Assignment assignment = parsed.getParsedAssignment();
            ITypeCheckResult result = assignment.typeCheck(environment);
            if (report(component, action, result.getProblems())) {
                continue;
            }
            for (String name : result.getInferredEnvironment().getNames()) {
                errors.add(component.name + " " + action.label() + ": " + name + " is not declared");
            }
            for (FreeIdentifier identifier : assignment.getAssignedIdentifiers()) {
                if (!variables.contains(identifier.getName())) {
                    errors.add(component.name + " " + action.label() + ": " + identifier.getName()
                        + " is not a variable");
                } else if (!assigned.add(identifier.getName())) {
                    errors.add(component.name + " " + action.label() + ": " + identifier.getName()
                        + " is assigned twice");
                }
            }
            for (FreeIdentifier identifier : assignment.getUsedIdentifiers()) {
                if (variables.contains(identifier.getName())) {
                    errors.add(component.name + " " + action.label() + ": the initialisation reads "
                        + identifier.getName());
                }
            }
        }
        for (String variable : component.identifiers) {
            if (!assigned.contains(variable)) {
                errors.add(component.name + ": " + variable + " is not initialised");
            }
        }
        return event.actions().size();
    }

    // MARK: Evaluation

    /** An element of a carrier set, named after the constant that denotes it. */
    record Atom(String name) {
        @Override
        public String toString() {
            return name;
        }
    }

    /** An ordered pair. */
    record Pair(Object left, Object right) {}

    /** A set that is not enumerated: a carrier set that no partition fixes, or a set of numbers. */
    record Universe(String name) {}

    /** Raised when a formula is not well defined or cannot be evaluated. */
    static final class EvaluationException extends RuntimeException {
        private static final long serialVersionUID = 1L;

        EvaluationException(String message) {
            super(message);
        }
    }

    /** The values of the constants, carrier sets and variables. */
    private final Map<String, Object> values = new HashMap<>();

    /**
     * Evaluates the invariants of a machine on the state after its initialisation.
     *
     * @param name the name of the machine
     */
    void evaluate(String name) {
        Component machine = components.get(name);
        if (machine == null || !machine.machine) {
            errors.add(name + ": the machine is not given");
            return;
        }
        ITypeEnvironmentBuilder environment = environments.get(name);
        List<Component> contexts = new ArrayList<>();
        collectContexts(machine, contexts);
        List<Predicate> axioms = new ArrayList<>();
        List<String> axiomLabels = new ArrayList<>();
        for (Component context : contexts) {
            for (String set : context.sets) {
                values.put(set, new Universe(set));
            }
            for (Element axiom : context.formulas) {
                axioms.add(typed(FACTORY.parsePredicate(axiom.text(), null).getParsedPredicate(), environment));
                axiomLabels.add(context.name + " " + axiom.label());
            }
        }
        boolean progress = true;
        Set<Integer> defining = new HashSet<>();
        while (progress) {
            progress = false;
            for (int i = 0; i < axioms.size(); i++) {
                if (!defining.contains(i) && define(axioms.get(i))) {
                    defining.add(i);
                    progress = true;
                }
            }
        }
        for (Component context : contexts) {
            for (String constant : context.identifiers) {
                if (!values.containsKey(constant)) {
                    errors.add(name + ": the axioms do not fix the value of " + constant);
                }
            }
        }
        if (!errors.isEmpty()) {
            return;
        }
        for (int i = 0; i < axioms.size(); i++) {
            report("axiom " + axiomLabels.get(i), axioms.get(i));
        }
        for (Event event : machine.events) {
            for (Element action : event.actions()) {
                Assignment assignment = typed(FACTORY.parseAssignment(action.text(), null).getParsedAssignment(),
                    environment);
                if (!(assignment instanceof BecomesEqualTo becomes)) {
                    errors.add(name + " " + action.label() + ": only deterministic assignments can be evaluated");
                    continue;
                }
                FreeIdentifier[] targets = becomes.getAssignedIdentifiers();
                for (int i = 0; i < targets.length; i++) {
                    try {
                        values.put(targets[i].getName(), value(becomes.getExpressions()[i], new ArrayList<>()));
                    } catch (EvaluationException problem) {
                        errors.add(name + " " + action.label() + ": " + problem.getMessage());
                    }
                }
            }
        }
        if (!errors.isEmpty()) {
            return;
        }
        for (Element invariant : machine.formulas) {
            report("invariant " + invariant.label(),
                typed(FACTORY.parsePredicate(invariant.text(), null).getParsedPredicate(), environment));
        }
    }

    private void report(String what, Predicate predicate) {
        try {
            System.out.println((truth(predicate, new ArrayList<>()) ? "holds " : "violated ") + what);
        } catch (EvaluationException problem) {
            System.out.println("undefined " + what + ": " + problem.getMessage());
        }
    }

    private void collectContexts(Component component, List<Component> contexts) {
        for (String parent : component.parents) {
            Component context = components.get(parent);
            collectContexts(context, contexts);
            if (!contexts.contains(context)) {
                contexts.add(context);
            }
        }
    }

    private static <T extends Formula<T>> T typed(T formula, ITypeEnvironmentBuilder environment) {
        formula.typeCheck(environment);
        return formula;
    }

    /**
     * Takes the values that an axiom fixes: a constant equal to an expression that can be evaluated, or the atoms of
     * a partition into singletons of constants.
     */
    private boolean define(Predicate axiom) {
        if (axiom.getTag() == Formula.EQUAL) {
            RelationalPredicate equality = (RelationalPredicate) axiom;
            if (equality.getLeft() instanceof FreeIdentifier constant && !values.containsKey(constant.getName())) {
                try {
                    values.put(constant.getName(), value(equality.getRight(), new ArrayList<>()));
                    return true;
                } catch (EvaluationException notYet) {
                    return false;
                }
            }
            return false;
        }
        if (axiom.getTag() != Formula.KPARTITION) {
            return false;
        }
        Expression[] parts = ((MultiplePredicate) axiom).getChildren();
        Set<Object> members = new LinkedHashSet<>();
        for (int i = 1; i < parts.length; i++) {
            if (!(parts[i] instanceof SetExtension singleton) || singleton.getMembers().length != 1
                || !(singleton.getMembers()[0] instanceof FreeIdentifier constant)) {
                return false;
            }
            values.putIfAbsent(constant.getName(), new Atom(constant.getName()));
            members.add(values.get(constant.getName()));
        }
        if (parts[0] instanceof FreeIdentifier set && values.get(set.getName()) instanceof Universe) {
            values.put(set.getName(), members);
        }
        return true;
    }

    private boolean truth(Predicate predicate, List<Object> bound) {
        switch (predicate.getTag()) {
            case Formula.BTRUE:
                return true;
            case Formula.BFALSE:
                return false;
            case Formula.LAND:
                for (Predicate child : ((AssociativePredicate) predicate).getChildren()) {
                    if (!truth(child, bound)) {
                        return false;
                    }
                }
                return true;
            case Formula.LOR:
                for (Predicate child : ((AssociativePredicate) predicate).getChildren()) {
                    if (truth(child, bound)) {
                        return true;
                    }
                }
                return false;
            case Formula.LIMP: {
                BinaryPredicate binary = (BinaryPredicate) predicate;
                return !truth(binary.getLeft(), bound) || truth(binary.getRight(), bound);
            }
            case Formula.LEQV: {
                BinaryPredicate binary = (BinaryPredicate) predicate;
                return truth(binary.getLeft(), bound) == truth(binary.getRight(), bound);
            }
            case Formula.NOT:
                return !truth(((UnaryPredicate) predicate).getChild(), bound);
            case Formula.KFINITE: {
                Object set = value(((SimplePredicate) predicate).getExpression(), bound);
                return set instanceof Set<?>;
            }
            case Formula.KPARTITION:
                return partition(((MultiplePredicate) predicate).getChildren(), bound);
            case Formula.FORALL:
            case Formula.EXISTS:
                return quantified((QuantifiedPredicate) predicate, bound);
            default:
                if (predicate instanceof RelationalPredicate relational) {
                    return relation(relational, bound);
                }
                throw new EvaluationException("the predicate " + predicate + " is not supported");
        }
    }

    private boolean partition(Expression[] children, List<Object> bound) {
        Set<Object> whole = set(value(children[0], bound));
        Set<Object> union = new HashSet<>();
        int count = 0;
        for (int i = 1; i < children.length; i++) {
            Set<Object> part = set(value(children[i], bound));
            count += part.size();
            union.addAll(part);
        }
        return count == union.size() && union.equals(whole);
    }

    private boolean quantified(QuantifiedPredicate predicate, List<Object> bound) {
        BoundIdentDecl[] declarations = predicate.getBoundIdentDecls();
        boolean universal = predicate.getTag() == Formula.FORALL;
        for (List<Object> assignment : assignments(declarations)) {
            List<Object> inner = new ArrayList<>(bound);
            inner.addAll(assignment);
            if (truth(predicate.getPredicate(), inner) != universal) {
                return !universal;
            }
        }
        return universal;
    }

    private List<List<Object>> assignments(BoundIdentDecl[] declarations) {
        List<List<Object>> result = new ArrayList<>();
        result.add(new ArrayList<>());
        for (BoundIdentDecl declaration : declarations) {
            List<Object> domain = enumerate(declaration.getType());
            List<List<Object>> next = new ArrayList<>();
            for (List<Object> prefix : result) {
                for (Object value : domain) {
                    List<Object> extended = new ArrayList<>(prefix);
                    extended.add(value);
                    next.add(extended);
                }
            }
            result = next;
        }
        return result;
    }

    private List<Object> enumerate(Type type) {
        if (type instanceof GivenType given) {
            Object set = values.get(given.getName());
            if (set instanceof Set<?> members) {
                return new ArrayList<>(members);
            }
            throw new EvaluationException("the carrier set " + given.getName() + " is not enumerated");
        }
        if (type.equals(FACTORY.makeBooleanType())) {
            return List.of(Boolean.TRUE, Boolean.FALSE);
        }
        if (type instanceof PowerSetType power) {
            List<Object> base = enumerate(power.getBaseType());
            if (base.size() > 16) {
                throw new EvaluationException("a set of " + base.size() + " elements has too many subsets");
            }
            List<Object> subsets = new ArrayList<>();
            for (int mask = 0; mask < (1 << base.size()); mask++) {
                Set<Object> subset = new HashSet<>();
                for (int i = 0; i < base.size(); i++) {
                    if ((mask & (1 << i)) != 0) {
                        subset.add(base.get(i));
                    }
                }
                subsets.add(subset);
            }
            return subsets;
        }
        if (type instanceof ProductType product) {
            List<Object> pairs = new ArrayList<>();
            for (Object left : enumerate(product.getLeft())) {
                for (Object right : enumerate(product.getRight())) {
                    pairs.add(new Pair(left, right));
                }
            }
            return pairs;
        }
        throw new EvaluationException("values of type " + type + " cannot be enumerated");
    }

    private boolean relation(RelationalPredicate predicate, List<Object> bound) {
        int tag = predicate.getTag();
        if (tag == Formula.IN || tag == Formula.NOTIN) {
            boolean member = member(value(predicate.getLeft(), bound), predicate.getRight(), bound);
            return tag == Formula.IN ? member : !member;
        }
        Object left = value(predicate.getLeft(), bound);
        Object right = value(predicate.getRight(), bound);
        switch (tag) {
            case Formula.EQUAL:
                return Objects.equals(left, right);
            case Formula.NOTEQUAL:
                return !Objects.equals(left, right);
            case Formula.LT:
                return number(left).compareTo(number(right)) < 0;
            case Formula.LE:
                return number(left).compareTo(number(right)) <= 0;
            case Formula.GT:
                return number(left).compareTo(number(right)) > 0;
            case Formula.GE:
                return number(left).compareTo(number(right)) >= 0;
            case Formula.SUBSETEQ:
                return set(left).stream().allMatch(element -> contains(right, element));
            case Formula.SUBSET:
                return set(right).containsAll(set(left)) && !set(left).equals(set(right));
            default:
                throw new EvaluationException("the predicate " + predicate + " is not supported");
        }
    }

    /** Whether a value is a member of a set, including sets of relations and functions, which are not built. */
    private boolean member(Object element, Expression set, List<Object> bound) {
        int tag = set.getTag();
        if (tag == Formula.REL || tag == Formula.PFUN || tag == Formula.TFUN) {
            BinaryExpression space = (BinaryExpression) set;
            Object domain = value(space.getLeft(), bound);
            Object range = value(space.getRight(), bound);
            Set<Object> sources = new HashSet<>();
            for (Object item : set(element)) {
                Pair pair = (Pair) item;
                if (!contains(domain, pair.left()) || !contains(range, pair.right())) {
                    return false;
                }
                if (!sources.add(pair.left()) && tag != Formula.REL) {
                    return false;
                }
            }
            return tag != Formula.TFUN || sources.equals(set(domain));
        }
        if (tag == Formula.POW) {
            Object base = value(((UnaryExpression) set).getChild(), bound);
            return set(element).stream().allMatch(item -> contains(base, item));
        }
        return contains(value(set, bound), element);
    }

    private boolean contains(Object set, Object element) {
        if (set instanceof Universe) {
            return true;
        }
        return set(set).contains(element);
    }

    @SuppressWarnings("unchecked")
    private static Set<Object> set(Object value) {
        if (value instanceof Set<?>) {
            return (Set<Object>) value;
        }
        throw new EvaluationException("a finite set is expected instead of " + value);
    }

    private static BigInteger number(Object value) {
        if (value instanceof BigInteger number) {
            return number;
        }
        throw new EvaluationException("a number is expected instead of " + value);
    }

    private Object value(Expression expression, List<Object> bound) {
        switch (expression.getTag()) {
            case Formula.FREE_IDENT: {
                String name = ((FreeIdentifier) expression).getName();
                if (!values.containsKey(name)) {
                    throw new EvaluationException(name + " has no value");
                }
                return values.get(name);
            }
            case Formula.BOUND_IDENT:
                return bound.get(bound.size() - 1 - ((BoundIdentifier) expression).getBoundIndex());
            case Formula.INTLIT:
                return ((IntegerLiteral) expression).getValue();
            case Formula.TRUE:
                return Boolean.TRUE;
            case Formula.FALSE:
                return Boolean.FALSE;
            case Formula.EMPTYSET:
                return new HashSet<>();
            case Formula.INTEGER:
                return new Universe("ℤ");
            case Formula.BOOL:
                return new HashSet<>(List.of(Boolean.TRUE, Boolean.FALSE));
            case Formula.SETEXT: {
                Set<Object> members = new HashSet<>();
                for (Expression member : ((SetExtension) expression).getMembers()) {
                    members.add(value(member, bound));
                }
                return members;
            }
            case Formula.KBOOL:
                return truth(((BoolExpression) expression).getPredicate(), bound);
            case Formula.MAPSTO: {
                BinaryExpression binary = (BinaryExpression) expression;
                return new Pair(value(binary.getLeft(), bound), value(binary.getRight(), bound));
            }
            case Formula.BUNION:
            case Formula.BINTER: {
                Expression[] children = ((AssociativeExpression) expression).getChildren();
                Set<Object> result = new HashSet<>(set(value(children[0], bound)));
                for (int i = 1; i < children.length; i++) {
                    if (expression.getTag() == Formula.BUNION) {
                        result.addAll(set(value(children[i], bound)));
                    } else {
                        result.retainAll(set(value(children[i], bound)));
                    }
                }
                return result;
            }
            case Formula.PLUS:
            case Formula.MUL: {
                Expression[] children = ((AssociativeExpression) expression).getChildren();
                BigInteger result = number(value(children[0], bound));
                for (int i = 1; i < children.length; i++) {
                    BigInteger next = number(value(children[i], bound));
                    result = expression.getTag() == Formula.PLUS ? result.add(next) : result.multiply(next);
                }
                return result;
            }
            case Formula.SETMINUS: {
                BinaryExpression binary = (BinaryExpression) expression;
                Set<Object> result = new HashSet<>(set(value(binary.getLeft(), bound)));
                result.removeAll(set(value(binary.getRight(), bound)));
                return result;
            }
            case Formula.MINUS:
            case Formula.DIV:
            case Formula.MOD:
                return arithmetic((BinaryExpression) expression, bound);
            case Formula.UNMINUS:
                return number(value(((UnaryExpression) expression).getChild(), bound)).negate();
            case Formula.CONVERSE: {
                Set<Object> result = new HashSet<>();
                for (Object item : set(value(((UnaryExpression) expression).getChild(), bound))) {
                    Pair pair = (Pair) item;
                    result.add(new Pair(pair.right(), pair.left()));
                }
                return result;
            }
            case Formula.KDOM:
            case Formula.KRAN: {
                Set<Object> result = new HashSet<>();
                for (Object item : set(value(((UnaryExpression) expression).getChild(), bound))) {
                    Pair pair = (Pair) item;
                    result.add(expression.getTag() == Formula.KDOM ? pair.left() : pair.right());
                }
                return result;
            }
            case Formula.KCARD:
                return BigInteger.valueOf(set(value(((UnaryExpression) expression).getChild(), bound)).size());
            case Formula.RELIMAGE: {
                BinaryExpression binary = (BinaryExpression) expression;
                Set<Object> sources = set(value(binary.getRight(), bound));
                Set<Object> result = new HashSet<>();
                for (Object item : set(value(binary.getLeft(), bound))) {
                    Pair pair = (Pair) item;
                    if (sources.contains(pair.left())) {
                        result.add(pair.right());
                    }
                }
                return result;
            }
            case Formula.FUNIMAGE: {
                BinaryExpression binary = (BinaryExpression) expression;
                Object argument = value(binary.getRight(), bound);
                Object result = null;
                for (Object item : set(value(binary.getLeft(), bound))) {
                    Pair pair = (Pair) item;
                    if (pair.left().equals(argument)) {
                        if (result != null && !result.equals(pair.right())) {
                            throw new EvaluationException(binary.getLeft() + " is not a function at " + argument);
                        }
                        result = pair.right();
                    }
                }
                if (result == null) {
                    throw new EvaluationException(argument + " is outside the domain of " + binary.getLeft());
                }
                return result;
            }
            case Formula.CSET: {
                QuantifiedExpression comprehension = (QuantifiedExpression) expression;
                Set<Object> result = new HashSet<>();
                for (List<Object> assignment : assignments(comprehension.getBoundIdentDecls())) {
                    List<Object> inner = new ArrayList<>(bound);
                    inner.addAll(assignment);
                    if (truth(comprehension.getPredicate(), inner)) {
                        result.add(value(comprehension.getExpression(), inner));
                    }
                }
                return result;
            }
            default:
                throw new EvaluationException("the expression " + expression + " is not supported");
        }
    }

    private Object arithmetic(BinaryExpression expression, List<Object> bound) {
        BigInteger left = number(value(expression.getLeft(), bound));
        BigInteger right = number(value(expression.getRight(), bound));
        switch (expression.getTag()) {
            case Formula.MINUS:
                return left.subtract(right);
            case Formula.DIV:
                if (right.signum() == 0) {
                    throw new EvaluationException("division by zero");
                }
                return left.divide(right);
            default:
                if (left.signum() < 0 || right.signum() <= 0) {
                    throw new EvaluationException("mod is defined for natural numbers and a positive divisor");
                }
                return left.mod(right);
        }
    }
}
