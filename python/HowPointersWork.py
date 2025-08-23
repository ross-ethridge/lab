#! /usr/bin/env python3

num1 = 11
num2 = num1

print("num1 = {}; num2 = {}".format(num1, num2))


print("\n num1 points to mem addr:", id(num1))
print("\n num2 points to mem addr:", id(num2))

num2 = 22
print("\n Changed value of num2 to {}".format(num2))

print("\n num1 points to mem addr:", id(num1))
print("\n num2 points to mem addr:", id(num2))
print("\n A new mem addr was created bc integers are immutable")

print("\n now lets look at Dictionaries.")

dict1 = {
    'value': 11
}

dict2 = dict1

print("\n Value of dict1 is: {}".format(dict1))
print("\n Value of dict2 is: {}".format(dict2))

dict2['value'] = 22

print("\n After updates only to dict2:")
print("\n Value of dict1 is: {}".format(dict1))
print("\n Value of dict2 is: {}".format(dict2))

print("\n Updating the pointer updates both values because dictionaries are mutable")