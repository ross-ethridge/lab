#! /usr/bin/env python3

class Cookie:
    def __init__(self, color):
        self.color = color

    def get_color(self):
        return self.color
    
    def set_color(self, color):
        self.color = color

def main():
    cookie_one = Cookie('green')
    cookie_two = Cookie('blue')

    print('Cookie one is', cookie_one.get_color())
    print('Cookie two is', cookie_two.get_color())

    cookie_one.set_color('yellow')
    cookie_two.set_color('purple')

    print('Now cookie one is', cookie_one.get_color())
    print('Now cookie two is', cookie_two.get_color())


if __name__ == '__main__':
    main()