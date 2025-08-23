#! /usr/bin/env python3

# Constructor for nodes inside the linked list
class Node:
    def __init__(self, value):
        self.value = value
        self.next = None

## Constructor for my Ll
class LinkedList:
    def __init__(self, value):
        new_node = Node(value)
        self.head = new_node
        self.tail = new_node
        self.length = 1

    def print_list(self):
        temp = self.head
        while temp is not None:
            print(temp.value)
            temp = temp.next

    def make_empty(self):
        self.head = None
        self.tail = None
        self.length = 0
        
    def append(self, value):
        new_node = Node(value)
        if self.head is None: #Is the list empty?
            self.head = new_node
            self.tail = new_node
        else: #Are there items in the list?
            self.tail.next = new_node
            self.tail = new_node
        self.length += 1 #Increase the length by 1
        return True
    
    def pop(self):
        if self.length == 0:
            return None
        
        temp = self.head
        pre = self.head

        while temp.next is not None:
            pre = temp
            temp = temp.next
        self.tail = pre
        self.tail.next = None
        self.length -= 1

        if self.length == 0:
            self.head = None
            self.tail = None
        
        return temp
            
        
    def prepend(self, value):
        new_node = Node(value)
        if self.length == 0:
            self.head = new_node
            self.tail = new_node
        else:
            new_node.next = self.head
            self.head = new_node
        self.length += 1
        return True


    def popFirst(self):
        if self.length == 0:
            return None

        temp = self.head
        self.head = self.head.next
        temp.next = None
        self.length -= 1

        if self.length == 0:
            self.tail = None
        
        return temp
    
    def get_value(self, index):
        if index < 0 or index >= self.length:
            return None
        
        temp = self.head

        for _ in range(index):
            temp = temp.next
        return temp
    

    def set_value(self, index, value):
        temp = self.get_value(index)

        if temp is not None:
            temp.value = value
            return True
        return False
    

    def insert(self, index, value):
        if index < 0 or index >= self.length:
            return False
        
        if index == 0:
            return self.prepend(value)
        
        if index == self.length:
            return self.append(value)
        
        new_node = Node(value)
        
        temp = self.get_value(index - 1)

        new_node.next = temp.next
        temp.next = new_node
        self.length += 1
        return True


    def remove(self, index):
        if index < 0 or index >= self.length:
            return None
        
        if index == 0:
            return self.popFirst()
        
        if index == self.length -1:
            return self.pop()
        
        prev = self.get_value(index -1)
        temp = prev.next
        prev.next = temp.next
        temp.next = None
        self.length -= 1
        return temp
    

    def reverse(self):
        temp = self.head
        self.head = self.tail
        self.tail = temp

        after = temp.next
        before = None

        for _ in range(self.length):
            after = temp.next
            temp.next = before
            before = temp
            temp = after





my_linked_list = LinkedList(1)
my_linked_list.append(2)
my_linked_list.append(3)
my_linked_list.append(4)

my_linked_list.print_list()

print("\nreversing list\n")
my_linked_list.reverse()

my_linked_list.print_list()