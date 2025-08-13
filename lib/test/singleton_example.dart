class CounterSingleton {
  // 私有构造函数
  CounterSingleton._();

  // 全局静态的单例
  static final CounterSingleton instance = CounterSingleton._();

  // 私有变量
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
  }
}

void main() {
  print(CounterSingleton.instance._count);
  CounterSingleton.instance.increment();
  print(CounterSingleton.instance._count);
}
