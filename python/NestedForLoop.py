#! /usr/bin/env python3

def print_items(n):
    for i in range(n):
        for j in range(n):
            print(i,j)
    
    for k in range(n):
        print(k)


def main():
    print_items(10)
    print("This is O of N2; O of N Squared, more complex")
    print("Nested for loop makes it more complex")
    print("The last iteration it N; ON2 + N")
    print("O of 1 is the most efficient")
    print("O of N2 is the least efficient")
    print("O of LogN is the divide and conquer alg")
    print ("")

if __name__ == '__main__':
    main()
