class Animal{
    constructor(name){
        this.name = name;
    }

    sayHello(){
        return "我是<span style='color: red; font-weight: bold;'>" + this.name + '</span>';
    }
}

class Dog extends Animal{
    constructor(container, name){
        super(name)
        this.container = container;
    }

    sayHello(){
        var text = super.sayHello();
        text = "汪汪说：" + text;
        this.container.innerHTML = text;
    }
}
