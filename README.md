# Forenum: Type-Safe Enums for Fortran

## Quick Start & Usage Summary

**What is Forenum?**
Forenum is a small Fortran library providing a base type for creating type-safe enumerations. It requires a Fortran 2003 compliant compiler (or newer) and integrates seamlessly with CMake-based projects, aiming for broad compatibility while using essential modern Fortran features.

**How to Use:**

1.  **Add as Git Submodule:**
    In your project's root directory, run:
    ```bash
    git submodule add https://github.com/23jinny/forenum.git third_party/forenum
    ```
    *(You can adjust the path `third_party/forenum` if you prefer a different location like `external/` or `vendor/`.)*

2.  **Integrate with CMake:**
    In your main `CMakeLists.txt`:
    ```cmake
    # Add the forenum subdirectory (adjust path if you changed it above)
    add_subdirectory(third_party/forenum)

    # Link your target against mod_forenum
    target_link_libraries(your_application_target PRIVATE mod_forenum)
    ```
    *   `mod_forenum` is an `INTERFACE` library. Linking with `PRIVATE` is generally recommended and means `your_application_target` can use `forenum`. If other parts of your project also need `forenum`, they would link to it directly. For more details on `PUBLIC` or `INTERFACE` linking (e.g., if `your_application_target` is a library that exposes `forenum` types in its own API), please see the "Advanced CMake Integration" section below.

3.  **Define Your Enums in Fortran:**
    You can define your enums in any Fortran module where they are relevant (e.g., within `mod_my_application_logic.f90` or in a module specifically for your project's enumerations like `mod_my_project_enums.f90`). It's recommended to use `PascalCase_e` for enum type names (e.g., `MyColor_e`).
    ```fortran
    module mod_something
      use forenum, only: EnumBase_t  ! Import the base type
      implicit none
      private

      ! Publicly declare your new enum type and its named values
      public :: MyColor_e
      public :: COLOR_RED, COLOR_GREEN, COLOR_BLUE
      
      ! No additional components are typically needed within the type block itself.
      type, extends(EnumBase_t) :: MyColor_e
      end type MyColor_e

      ! Define specific enum values (1-based indexing used in this example)
      type(MyColor_e), parameter :: COLOR_RED   = MyColor_e(1)
      type(MyColor_e), parameter :: COLOR_GREEN = MyColor_e(2)
      type(MyColor_e), parameter :: COLOR_BLUE  = MyColor_e(3)

      ...
      
    end module mod_something
    ```

---
## Detailed Explanations & Advanced Topics

### Why was Forenum Created?

Fortran, by default, does not have a built-in mechanism for truly type-safe enumerations. Developers often resort to using integer parameters, which can lead to issues:
-   **Lack of Type Safety**: Integers intended for one "enum" set can be accidentally assigned or compared with integers from another, or with arbitrary integer values, without compiler errors.
-   **Readability**: While named integer parameters are better than magic numbers, they don't group related constants under a distinct type.
-   **Maintainability**: Managing sets of integer parameters can become cumbersome in larger projects.

Forenum addresses these by providing a base `abstract type` (`EnumBase_t`) from which specific enumeration types can be derived. This ensures that values from different enumerations cannot be inadvertently mixed or compared, as the compiler will enforce type checking.

### Design Choices

-   **Fortran 2003 (Minimum Standard)**: This library requires a Fortran 2003 compliant compiler as a minimum. It leverages features from this standard, such as `abstract type` and `type extension`, which are crucial for the base enum implementation. This allows for a common interface while ensuring derived enum types are distinct, aiming for wide compatibility with modern Fortran projects.
-   **CMake for Building**: The project uses CMake for its build system. CMake is a powerful, cross-platform build system generator that is widely adopted and well-suited for Fortran projects. It simplifies the process of integrating `forenum` into other CMake-based projects as a submodule.
-   **Simplicity and Reusability**: The core idea is to provide a minimal, easy-to-understand base that developers can extend to create their own specific enum types with minimal boilerplate.

### Advanced CMake Integration

**Understanding CMake Keywords for `mod_forenum`:**

The `mod_forenum` library is defined as an `INTERFACE` library in its own `CMakeLists.txt`:
```cmake
# In forenum/CMakeLists.txt:
add_library(mod_forenum INTERFACE)
target_sources(mod_forenum INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/src/forenum.f90")
target_include_directories(mod_forenum INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/src")
```
-   `add_library(mod_forenum INTERFACE)`: This declares that `mod_forenum` doesn't compile into a separate library file. Instead, its properties (like source files and include directories) are "interfaced" to consuming targets.
-   `target_sources(mod_forenum INTERFACE ...)`: This specifies that `forenum.f90` is a source file that consuming targets need to compile.
-   `target_include_directories(mod_forenum INTERFACE ...)`: This specifies that the `src` directory (containing `forenum.f90`) should be added to the include path of consuming targets. The `INTERFACE` keyword here means this include directory is part of `mod_forenum`'s public interface and is *always* propagated to any target that links against `mod_forenum`, regardless of whether that link is `PRIVATE`, `PUBLIC`, or `INTERFACE`.

When you link your target to `mod_forenum` using `target_link_libraries`:
```cmake
target_link_libraries(your_application_target <PRIVATE|PUBLIC|INTERFACE> mod_forenum)
```
The keywords `PRIVATE`, `PUBLIC`, and `INTERFACE` control how the *usage requirements* of `mod_forenum` (like its include directories and source files defined with `INTERFACE` in its own `CMakeLists.txt`) are propagated *further* if `your_application_target` is itself a library.

*   **`PRIVATE`**: If `your_application_target` links to `mod_forenum` with `PRIVATE`, it means `your_application_target` uses `mod_forenum` for its internal implementation. The properties of `mod_forenum` are applied to `your_application_target`. However, if another target (e.g., `final_executable`) links to `your_application_target` (which is a library), `mod_forenum`'s properties are *not* propagated to `final_executable`. If `final_executable` also needs `forenum`, it must link to `mod_forenum` directly.

*   **`PUBLIC`**: If `your_application_target` (a library) links to `mod_forenum` with `PUBLIC`, it means `mod_forenum` is part of `your_application_target`'s public API. The properties of `mod_forenum` are applied to `your_application_target`, AND they are also propagated to any target that links to `your_application_target`. This allows those downstream targets to also `use forenum` without linking to `mod_forenum` explicitly.

*   **`INTERFACE`**: If `your_application_target` is *itself* an `INTERFACE` library and links to `mod_forenum` with `INTERFACE`, it means `mod_forenum`'s properties are added to `your_application_target`'s own interface properties, to be propagated to whatever links to `your_application_target`.

In summary:
-   The `INTERFACE` keyword in `target_sources` and `target_include_directories` within `forenum/CMakeLists.txt` defines *what* `mod_forenum` provides to direct consumers.
-   The `PRIVATE`/`PUBLIC`/`INTERFACE` keywords in `target_link_libraries` in your project's `CMakeLists.txt` control *how far* those provisions are propagated if your target is also a library. For an executable target, `PRIVATE` is usually sufficient.

**Multiple Targets Depending on `forenum`:**

If multiple targets (e.g., several libraries and executables) within your larger project need to use `forenum`:
1.  Call `add_subdirectory(third_party/forenum)` once, typically in a high-level `CMakeLists.txt` file if possible. If `add_subdirectory` for `forenum` is called multiple times with the same submodule path, CMake usually handles this correctly by processing the `forenum` project only once, ensuring the `mod_forenum` target is defined uniquely.
2.  Each target that directly uses `forenum` (i.e., has `use forenum` in its Fortran source) must explicitly link to `mod_forenum` via `target_link_libraries(... mod_forenum)`.

Because `mod_forenum` is an `INTERFACE` library, there are no conflicting compiled library files. CMake ensures that `forenum.f90` is compiled as needed by each consuming target and that the Fortran module (`forenum.mod`) is correctly found.

---
## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
