#! /usr/bin/env python3

def print_items(count):
    print("First loop, O of N")
    for i in range(count):
        print(i)

    print("Second loop has same run time")
    for j in range(count):
        print(j)


def main():
    print("This is O of N; Linear for each run of the for loop")
    print_items(10)

if __name__ == '__main__':
    main()
