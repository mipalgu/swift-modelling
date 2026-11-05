# Advanced statistical analysis
# Complex calculations and comparisons

# Median (sorted middle value; positions start at 1)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->collect(e | e.salary)
        ->sortedBy(s | s)
    in let size = salaries->size()
    in if size.mod(2) = 0
       then (salaries->at(size / 2) + salaries->at(size / 2 + 1)) / 2
       else salaries->at((size + 1) / 2)
       endif"

# Output: 125000.0

# Correlation indicator: experience versus salary
# (the average experience uses integer division)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees
    in let avgExp = employees->collect(e | e.yearsOfService)->sum() / employees->size(),
           avgSal = employees->collect(e | e.salary)->sum() / employees->size()
    in let highExpHighSal = employees
        ->select(e | e.yearsOfService > avgExp and e.salary > avgSal)->size(),
       lowExpLowSal = employees
        ->select(e | e.yearsOfService <= avgExp and e.salary <= avgSal)->size()
    in 'positive: ' + (highExpHighSal + lowExpLowSal).toString()
        + ', negative: '
        + (employees->size() - highExpHighSal - lowExpLowSal).toString()
        + ', indicator: '
        + ((highExpHighSal + lowExpLowSal) * 100 / employees->size()).toString() + '%'"

# Output: "positive: 14, negative: 1, indicator: 93%"

# Salary quartile analysis (positions (n + 1) / 4, (n + 1) / 2 and 3(n + 1) / 4)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->collect(e | e.salary)
        ->sortedBy(s | s),
        q1Index = (salaries->size() + 1) / 4,
        q2Index = (salaries->size() + 1) / 2,
        q3Index = (salaries->size() + 1) * 3 / 4
    in 'q1: ' + salaries->at(q1Index.max(1)).toString()
        + ', median: ' + salaries->at(q2Index.max(1)).toString()
        + ', q3: ' + salaries->at(q3Index.max(1)).toString()
        + ', iqr: '
        + (salaries->at(q3Index.max(1)) - salaries->at(q1Index.max(1))).toString()"

# Output: "q1: 105000.0, median: 125000.0, q3: 150000.0, iqr: 45000.0"

# Department comparison metrics
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let depts = organisation.departments,
        overallAvgSalary = depts
            ->collect(d | d.employees->collect(e | e.salary)->sum()
                / d.employees->size())
            ->sum() / depts->size()
    in depts->collect(d |
        let avgSalary = d.employees->collect(e | e.salary)->sum()
                        / d.employees->size(),
            avgExperience = d.employees->collect(e | e.yearsOfService)->sum()
                            / d.employees->size()
        in d.name + ': average salary ' + avgSalary.toString()
            + ', average experience ' + avgExperience.toString()
            + ', above organisation average: '
            + (avgSalary > overallAvgSalary).toString())"

# Output: ["Engineering: average salary 142500.0, average experience 7, above organisation average: true", ..., "Operations: average salary 116666.66666666667, average experience 8, above organisation average: false"]

# Project risk score (based on dependencies and incomplete milestones)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->sortedBy(p | -(p.dependencies->size() * 10
        + p.milestones->reject(m | m.completed)->size() * 20))
    ->collect(p | let depCount = p.dependencies->size(),
        incompleteMilestones = p.milestones->reject(m | m.completed)->size(),
        totalMilestones = p.milestones->size()
    in p.name + ': risk score '
        + (depCount * 10 + incompleteMilestones * 20).toString()
        + ', completion '
        + (if totalMilestones > 0
           then (totalMilestones - incompleteMilestones) * 100 / totalMilestones
           else 0 endif).toString() + '%')"

# Output: ["Analytics Dashboard: risk score 60, completion 0%", "Customer Portal: risk score 40, completion 50%", "Infrastructure Modernisation: risk score 30, completion 66%", "Mobile App Redesign: risk score 20, completion 66%"]
