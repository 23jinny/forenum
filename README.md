# forenum: Type-Safe Enums for Fortran

## Quick Start & Usage Summary

**What is forenum?**
forenum (short for "fortran enumerations") is a small Fortran library providing a base type for creating type-safe enumerations. It requires at least a Fortran 2003 compliant compiler and integrates seamlessly with CMake-based projects, aiming for broad compatibility while using essential modern Fortran features.

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

    # Link your target against forenum
    target_link_libraries(your_application_target PRIVATE forenum)
    ```
    *   `forenum` is an `INTERFACE` library. Linking with `PRIVATE` is generally recommended and means `your_application_target` can use `forenum`. If other parts of your project also need `forenum`, they would link to it directly. For more details on `PUBLIC` or `INTERFACE` linking (e.g., if `your_application_target` is a library that exposes `forenum` types in its own API), please see the "Advanced CMake Integration" section below.

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

## Why Use Enums? The Problem with Magic Numbers

One of the primary motivations for using enumerations (enums) is to eliminate "magic numbers" and improve code clarity and maintainability.

### What are Magic Numbers?

Magic numbers are unnamed numerical constants that appear directly in code without any explanation of their meaning. For example, `status = 1` or `if (interaction_type == 3)`. While the programmer might know what `1` or `3` means at the time of writing, it's often obscure to others (or even to the original programmer later).

It's important to distinguish these from other numerical constants that might also be initially written as "magic numbers" but are better addressed by named compile-time constants (e.g., `integer, parameter :: MAX_ITERATIONS = 1000` or `real, parameter :: PI = 3.14159265`). While named constants improve readability for standalone values like physical constants or configuration limits, enums (like those provided by forenum) are particularly powerful for defining a *set of distinct, related states, modes, types, or options* (e.g., colors, status codes, command types). Enums offer not just names but also enhanced type safety, ensuring that, for instance, a color cannot be accidentally used where a status code is expected.

### Why are Magic Numbers Bad?

Using magic numbers can lead to several problems:

*   **Poor Readability:** Code becomes difficult to understand. What does `if (user_role == 2)` actually check? Is `2` an admin, a guest, or something else?
*   **Difficult Maintenance:** If a magic number needs to change (e.g., the value representing an "admin" role changes from `2` to `100`), you must find and replace every instance of that number, hoping you don't miss any or incorrectly change a `2` that meant something else.
*   **Error-Prone:** It's easy to mistype a number (e.g., `2` instead of `3`), leading to subtle bugs that are hard to track down.
*   **No Semantic Meaning:** The number itself doesn't convey its purpose. `COLOR_RED` is much clearer than `1`.
*   **No Type Safety:** The compiler can't help you if you accidentally assign `user_role = traffic_light_state`. They're all just integers.

### Example: Code with Magic Numbers

Consider this Fortran snippet from a simplified particle transport code:

```fortran
! --- Example with Magic Numbers (Illustrating "Bad Legacy Code") ---

subroutine process_particle_interaction_legacy(particle_energy, interaction_type)
  implicit none
  real, intent(inout) :: particle_energy
  integer, intent(in) :: interaction_type ! 1=elastic, 2=absorb, 3=fiss, 4=capt ??

  real :: energy_loss

  if (interaction_type == 1) then         ! Elastic scatter
    energy_loss = particle_energy * 0.1
    particle_energy = particle_energy - energy_loss
  else if (interaction_type == 2) then  ! Absorption
    particle_energy = 0.0
  else if (interaction_type == 3) then  ! Fission
    particle_energy = 0.0
  else if (interaction_type == 4) then  ! Capture
    particle_energy = 0.0
  else
    ! What happens if code is 5? Or 0? Or negative?
  end if
end subroutine process_particle_interaction_legacy

program test_legacy_interactions
  implicit none
  real :: p_energy
  integer :: interaction_type

  ! Fission (must remember 3 is fission)
  p_energy = 10.0
  interaction_type = 3 ! Fission
  call process_particle_interaction_legacy(p_energy, interaction_type)

  ! Elastic Scatter (must remember 1 is elastic)
  p_energy = 20.0
  interaction_type = 1 ! Elastic
  call process_particle_interaction_legacy(p_energy, interaction_type)

  ! No compile-time check for invalid codes:
  ! interaction_type = 5
  ! call process_particle_interaction_legacy(p_energy, interaction_type) ! Runs, but does 'else'
end program test_legacy_interactions
```

The meaning of `interaction_type = 3` is unclear without the comment and prone to errors.

### Solution: Using forenum Enums

With forenum, you can define a type-safe enumeration for `InteractionType_e` (something more specific like `ParticleInteractionType_e` should be more appropriate, but this is a mouthful for this example):

```fortran
! --- Refactored Example with Enums ---
module mod_particle_processing
  use forenum, only: EnumBase_t
  implicit none
  private

  public :: InteractionType_e
  public :: IT_ELASTIC_SCATTER, IT_ABSORPTION, IT_FISSION, IT_CAPTURE
  public :: process_particle_interaction

  type, extends(EnumBase_t) :: InteractionType_e
  end type InteractionType_e

  type(InteractionType_e), parameter :: IT_ELASTIC_SCATTER = InteractionType_e(1)
  type(InteractionType_e), parameter :: IT_ABSORPTION      = InteractionType_e(2)
  type(InteractionType_e), parameter :: IT_FISSION         = InteractionType_e(3)
  type(InteractionType_e), parameter :: IT_CAPTURE         = InteractionType_e(4)

contains

  subroutine process_particle_interaction(particle_energy, interaction_type)
    real, intent(inout) :: particle_energy
    type(InteractionType_e), intent(in) :: interaction_type
    real :: energy_loss

    select case (interaction_type)
    case (IT_ELASTIC_SCATTER)
      energy_loss = particle_energy * 0.1
      particle_energy = particle_energy - energy_loss
    case (IT_ABSORPTION)
      particle_energy = 0.0
    case (IT_FISSION)
      particle_energy = 0.0
    case (IT_CAPTURE)
      particle_energy = 0.0
    ! No default needed if all enum members are handled and type safety is leveraged
    end select
  end subroutine process_particle_interaction

end module mod_particle_processing_concise

program test_enum_interactions_concise
  use mod_particle_processing_concise
  implicit none
  real :: p_energy

  ! Fission
  p_energy = 10.0
  call process_particle_interaction(p_energy, IT_FISSION)

  ! Elastic Scatter
  p_energy = 20.0
  call process_particle_interaction(p_energy, IT_ELASTIC_SCATTER)

  ! Compiler checks prevent invalid types:
  ! call process_particle_interaction(p_energy, 3) ! Error: Type mismatch
end program test_enum_interactions_concise
```
This version is far more readable and type-safe. `IT_FISSION` clearly communicates intent.

### Some More Specific Examples of Enum Usage

Using a Monte Carlo particle transport program for example, some enums that would typically be used are:

*   **Particle Types:** Defining the kinds of particles being simulated (e.g., `ParticleType_e` with `NEUTRON`, `PHOTON`, `ELECTRON`, `PROTON`).
*   **Particle Termination Types:** Categorizing how a particle's history ends (e.g., `TerminationReason_e` with `TERMINATE_ABSORBED`, `TERMINATE_VACUUM_BC`, `TERMINATE_WEIGHT_CUTOFF`, `TERMINATE_ENERGY_CUTOFF`).
*   **Boundary Condition Types:** Marking special properties of geometric surfaces (e.g., `BoundaryCondition_e` with `BC_TRANSMISSIVE`, `BC_VACUUM`, `BC_REFLECTIVE`, `BC_PERIODIC`).
*   **Tally Types:** Specifying what quantity a tally is scoring (e.g., `TallyType_e` with `TALLY_FLUX`, `TALLY_CURRENT`, `TALLY_FISSION_RATE`).
*   **Cross-Section Types:** Differentiating types of cross-section data (e.g., `XS_Type_e` with `XS_TOTAL`, `XS_ELASTIC`, `XS_FISSION`).

By using enums, you make your Fortran code more robust, readable, and maintainable. forenum provides the tools to easily create and use such type-safe enumerations in your projects.

---

## Detailed Explanations & Advanced Topics

### Why was forenum Created?

Fortran, by default, does not have a built-in mechanism for truly type-safe enumerations. Developers often resort to using integer parameters, which can lead to issues:
-   **Lack of Type Safety**: Integers intended for one "enum" set can be accidentally assigned or compared with integers from another, or with arbitrary integer values, without compiler errors.
-   **Readability**: While named integer parameters are better than magic numbers, they don't group related constants under a distinct type.
-   **Maintainability**: Managing sets of integer parameters can become cumbersome in larger projects.

forenum addresses these by providing a base `abstract type` (`EnumBase_t`) from which specific enumeration types can be derived. This ensures that values from different enumerations cannot be inadvertently mixed or compared, as the compiler will enforce type checking.

### Design Choices

-   **Fortran 2003 (Minimum Standard)**: This library requires a Fortran 2003 compliant compiler as a minimum. It leverages features from this standard, such as `abstract type` and `type extension`, which are crucial for the base enum implementation. This allows for a common interface while ensuring derived enum types are distinct, aiming for wide compatibility with modern Fortran projects.
-   **CMake for Building**: The project uses CMake for its build system. CMake is a powerful, cross-platform build system generator that is widely adopted and well-suited for Fortran projects. It simplifies the process of integrating `forenum` into other CMake-based projects as a submodule.
-   **Simplicity and Reusability**: The core idea is to provide a minimal, easy-to-understand base that developers can extend to create their own specific enum types with minimal boilerplate.

### Advanced CMake Integration

**Understanding CMake Keywords for `forenum`:**

The `forenum` library is defined as an `INTERFACE` library in its own `CMakeLists.txt`:
```cmake
# In forenum/CMakeLists.txt:
add_library(forenum INTERFACE)
target_sources(forenum INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/src/forenum.f90")
target_include_directories(forenum INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/src")
```
-   `add_library(forenum INTERFACE)`: This declares that `forenum` doesn't compile into a separate library file. Instead, its properties (like source files and include directories) are "interfaced" to consuming targets.
-   `target_sources(forenum INTERFACE ...)`: This specifies that `forenum.f90` is a source file that consuming targets need to compile.
-   `target_include_directories(forenum INTERFACE ...)`: This specifies that the `src` directory (containing `forenum.f90`) should be added to the include path of consuming targets. The `INTERFACE` keyword here means this include directory is part of `forenum`'s public interface and is *always* propagated to any target that links against `forenum`, regardless of whether that link is `PRIVATE`, `PUBLIC`, or `INTERFACE`.

When you link your target to `forenum` using `target_link_libraries`:
```cmake
target_link_libraries(your_application_target <PRIVATE|PUBLIC|INTERFACE> forenum)
```
The keywords `PRIVATE`, `PUBLIC`, and `INTERFACE` control how the *usage requirements* of `forenum` (like its include directories and source files defined with `INTERFACE` in its own `CMakeLists.txt`) are propagated *further* if `your_application_target` is itself a library.

*   **`PRIVATE`**: If `your_application_target` links to `forenum` with `PRIVATE`, it means `your_application_target` uses `forenum` for its internal implementation. The properties of `forenum` are applied to `your_application_target`. However, if another target (e.g., `final_executable`) links to `your_application_target` (which is a library), `forenum`'s properties are *not* propagated to `final_executable`. If `final_executable` also needs `forenum`, it must link to `forenum` directly.

*   **`PUBLIC`**: If `your_application_target` (a library) links to `forenum` with `PUBLIC`, it means `forenum` is part of `your_application_target`'s public API. The properties of `forenum` are applied to `your_application_target`, AND they are also propagated to any target that links to `your_application_target`. This allows those downstream targets to also `use forenum` without linking to `forenum` explicitly.

*   **`INTERFACE`**: If `your_application_target` is *itself* an `INTERFACE` library and links to `forenum` with `INTERFACE`, it means `forenum`'s properties are added to `your_application_target`'s own interface properties, to be propagated to whatever links to `your_application_target`.

In summary:
-   The `INTERFACE` keyword in `target_sources` and `target_include_directories` within `forenum/CMakeLists.txt` defines *what* `forenum` provides to direct consumers.
-   The `PRIVATE`/`PUBLIC`/`INTERFACE` keywords in `target_link_libraries` in your project's `CMakeLists.txt` control *how far* those provisions are propagated if your target is also a library. For an executable target, `PRIVATE` is usually sufficient.

**Multiple Targets Depending on `forenum`:**

If multiple targets (e.g., several libraries and executables) within your larger project need to use `forenum`:
1.  Call `add_subdirectory(third_party/forenum)` once, typically in a high-level `CMakeLists.txt` file if possible. If `add_subdirectory` for `forenum` is called multiple times with the same submodule path, CMake usually handles this correctly by processing the `forenum` project only once, ensuring the `forenum` target is defined uniquely.
2.  Each target that directly uses `forenum` (i.e., has `use forenum` in its Fortran source) must explicitly link to `forenum` via `target_link_libraries(... forenum)`.

Because `forenum` is an `INTERFACE` library, there are no conflicting compiled library files. CMake ensures that `forenum.f90` is compiled as needed by each consuming target and that the Fortran module (`forenum.mod`) is correctly found.

---
## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
