# Impact analysis queries
# Assess the impact of changes or events

# Impact of employee departure, highest impact first
# (score: 10 per project, 20 per direct report, 5 per mentee)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees
    in employees
        ->sortedBy(e | -(e.assignedProjects->size() * 10
            + e.directReports->size() * 20
            + employees->select(emp | emp.mentors->includes(e))->size() * 5))
        ->collect(e | let mentees = employees->select(emp | emp.mentors->includes(e))
            in e.name + ' (' + e.role + '): projects '
                + e.assignedProjects->size().toString()
                + ', reports ' + e.directReports->size().toString()
                + ', mentees ' + mentees->size().toString()
                + ', score ' + (e.assignedProjects->size() * 10
                    + e.directReports->size() * 20
                    + mentees->size() * 5).toString())"

# Output: ["Jessica Moore (Product Director): projects 3, reports 2, mentees 0, score 70", "Olivia Martinez (Design Director): projects 2, reports 2, mentees 0, score 60", "James Wong (Senior Engineer): projects 1, reports 2, mentees 1, score 55", ..., "Jack Robinson (Operations Analyst): projects 0, reports 0, mentees 0, score 0"]

# Budget cut impact analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let cutPercentage = 20
    in organisation.departments
        ->collect(d | let newBudget = d.budget * (100 - cutPercentage) / 100,
            currentSalaryCost = d.employees->collect(e | e.salary)->sum()
        in d.name + ': proposed budget ' + newBudget.toString()
            + ', salaries ' + currentSalaryCost.toString()
            + ', surplus ' + (newBudget - currentSalaryCost).toString()
            + ', viable: ' + (newBudget >= currentSalaryCost).toString())"

# Output: ["Engineering: proposed budget 2000000.0, salaries 570000.0, surplus 1430000.0, viable: true", "Product: proposed budget 960000.0, salaries 510000.0, surplus 450000.0, viable: true", "Design: proposed budget 720000.0, salaries 480000.0, surplus 240000.0, viable: true", "Operations: proposed budget 560000.0, salaries 350000.0, surplus 210000.0, viable: true"]

# Project delay impact (direct dependants and their dependants)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | let wouldDelay = organisation.projects
            ->select(other | other.dependencies->includes(p)),
        cascade = wouldDelay
            ->collect(delayed | organisation.projects
                ->select(further | further.dependencies->includes(delayed)))
            ->asSet()
        in p.name + ': delays ' + wouldDelay->size().toString()
            + ' directly, ' + cascade->size().toString() + ' at the next level')"

# Output: ["Customer Portal: delays 2 directly, 1 at the next level", "Infrastructure Modernisation: delays 1 directly, 0 at the next level", "Mobile App Redesign: delays 0 directly, 0 at the next level", "Analytics Dashboard: delays 0 directly, 0 at the next level"]

# Skill gap impact if employees leave (skills held by only one person)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let allEmployees = organisation.departments.employees,
        uniqueSkills = allEmployees->collect(e | e.skills)->asSet()
    in uniqueSkills
        ->select(skill | allEmployees->select(e | e.skills->includes(skill))->size() = 1)
        ->collect(skill | skill + ': '
            + allEmployees->select(e | e.skills->includes(skill))->first().name)"

# Output: ["Kotlin: James Wong", "Python: Emily Chen", "Testing: Emily Chen", ..., "SupplyChain: William Anderson", ..., "Reporting: Jack Robinson"]

# Department reorganisation impact
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let deptToMerge = organisation.departments
        ->select(d | d.code = 'DES')->first()
    in deptToMerge.name + ': employees ' + deptToMerge.employees->size().toString()
        + ', projects affected '
        + organisation.projects
            ->select(p | p.teamMembers->exists(e | e.eContainer() = deptToMerge))
            ->size().toString()
        + ', collaborations affected '
        + organisation.departments
            ->select(d | d.collaboratesWith->includes(deptToMerge))
            ->size().toString()"

# Output: "Design: employees 4, projects affected 2, collaborations affected 2"

# Priority change impact: people shared between priority 1 projects
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects->select(p | p.priority = 1)
    ->collect(p | organisation.projects
        ->select(other | other.priority = 1 and other <> p)
        ->collect(other | other.teamMembers
            ->intersection(p.teamMembers)
            ->collect(e | p.name + ' shares ' + e.name + ' with ' + other.name)))"

# Output: ["Customer Portal shares Emily Chen with Mobile App Redesign", "Customer Portal shares Rachel Adams with Mobile App Redesign", ..., "Mobile App Redesign shares Olivia Martinez with Customer Portal"]
