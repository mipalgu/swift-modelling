# Advanced statistical analysis
# Complex calculations and comparisons

# Median approximation (sorted middle value)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->flatten()
        ->collect(e | e.salary)
        ->sortedBy(s | s)
    in let size = salaries->size()
    in if size.mod(2) = 0
       then (salaries->at(size / 2) + salaries->at(size / 2 + 1)) / 2
       else salaries->at((size + 1) / 2)
       endif"

# Output: 120000.0 (median salary)

# Correlation indicator: experience vs salary
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let employees = organisation.departments.employees->flatten()
    in let avgExp = employees->collect(e | e.yearsOfService)->sum() / employees->size(),
           avgSal = employees->collect(e | e.salary)->sum() / employees->size()
    in let highExpHighSal = employees
        ->select(e | e.yearsOfService > avgExp and e.salary > avgSal)->size(),
       lowExpLowSal = employees
        ->select(e | e.yearsOfService <= avgExp and e.salary <= avgSal)->size()
    in Tuple{
        positiveCorrelation = highExpHighSal + lowExpLowSal,
        negativeCorrelation = employees->size() - highExpHighSal - lowExpLowSal,
        correlationIndicator = (highExpHighSal + lowExpLowSal) * 100 / employees->size()}"

# Output: {positiveCorrelation: 12, negativeCorrelation: 9, correlationIndicator: 57}

# Salary quartile analysis
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let salaries = organisation.departments.employees
        ->flatten()
        ->collect(e | e.salary)
        ->sortedBy(s | s),
        q1Index = salaries->size() / 4,
        q2Index = salaries->size() / 2,
        q3Index = salaries->size() * 3 / 4
    in Tuple{
        q1 = salaries->at(q1Index.max(1)),
        median = salaries->at(q2Index.max(1)),
        q3 = salaries->at(q3Index.max(1)),
        iqr = salaries->at(q3Index.max(1)) - salaries->at(q1Index.max(1))}"

# Output: {q1: 105000.0, median: 120000.0, q3: 145000.0, iqr: 40000.0}

# Department comparison metrics
swift-aql evaluate --model enterprise-data.xmi \
  --expression "let deptMetrics = organisation.departments
        ->collect(d | Tuple{
            name = d.name,
            avgSalary = d.employees->collect(e | e.salary)->sum()
                        / d.employees->size(),
            avgExperience = d.employees->collect(e | e.yearsOfService)->sum()
                            / d.employees->size()})
    in let overallAvgSalary = deptMetrics->collect(m | m.avgSalary)->sum()
                              / deptMetrics->size()
    in deptMetrics->collect(m | Tuple{
        department = m.name,
        avgSalary = m.avgSalary,
        avgExperience = m.avgExperience,
        aboveOrgAvg = m.avgSalary > overallAvgSalary})"

# Output: [{department: "Engineering", avgSalary: 142500.0, avgExperience: 7.0, aboveOrgAvg: true}, ...]

# Project risk score (based on dependencies and incomplete milestones)
swift-aql evaluate --model enterprise-data.xmi \
  --expression "organisation.projects
    ->collect(p | let depCount = p.dependencies->size(),
        incompleteMilestones = p.milestones->reject(m | m.completed)->size(),
        totalMilestones = p.milestones->size()
    in Tuple{
        project = p.name,
        riskScore = depCount * 10 + incompleteMilestones * 20,
        completionRate = if totalMilestones > 0
            then (totalMilestones - incompleteMilestones) * 100 / totalMilestones
            else 0 endif})
    ->sortedBy(p | -p.riskScore)"

# Output: [{project: "Analytics Dashboard", riskScore: 60, completionRate: 0}, ...]
