function [t1_list, meanAge] = spikeSortByAge(Min_age, Max_age, t1_list, Protocol)
ages = [];
i = 0;
for t1 = t1_list
    i = i+1;
row_number1 = find(Protocol.ID == t1, 1);
ages(i) = Protocol.age(row_number1);
end

t1_list(not(Min_age<ages & ages<Max_age)) = [];



meanAge = mean(ages(Min_age<ages & ages<Max_age));

end