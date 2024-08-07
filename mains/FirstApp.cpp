#include <argparse/argparse.hpp>
#include <cstdlib>
#include <exception>
#include <iostream>

#include "../apps/first_app.hpp"

int main(int argc, char *argv[]) {
   argparse::ArgumentParser program("SIP - headless");

   program.add_argument("square")
       .help("display the square of a given integer")
       .scan<'i', int>();

   try {
      program.parse_args(argc, argv);
   } catch (const std::exception &err) {
      std::cerr << err.what() << std::endl;
      std::cerr << program;
      return 1;
   }

   auto input = program.get<int>("square");

   lve::FirstApp app{input};

   try {
      app.run();
   } catch (const std::exception &e) {
      std::cerr << e.what() << '\n';
      return EXIT_FAILURE;
   }

   return EXIT_SUCCESS;
}
