! --- Define First Enum: MyColor_e ---
module mod_my_colors
  use forenum, only: EnumBase_t
  implicit none
  private

  public :: MyColor_e
  public :: COLOR_RED, COLOR_GREEN, COLOR_BLUE
  
  type, extends(EnumBase_t) :: MyColor_e
  end type MyColor_e

  type(MyColor_e), parameter :: COLOR_RED   = MyColor_e(1)
  type(MyColor_e), parameter :: COLOR_GREEN = MyColor_e(2)
  type(MyColor_e), parameter :: COLOR_BLUE  = MyColor_e(3)
end module mod_my_colors

! --- Define Second Enum: MyDirection_e ---
module mod_my_directions
  use forenum, only: EnumBase_t
  implicit none
  private

  public :: MyDirection_e
  public :: DIR_NORTH, DIR_SOUTH, DIR_EAST, DIR_WEST
  
  type, extends(EnumBase_t) :: MyDirection_e
  end type MyDirection_e

  type(MyDirection_e), parameter :: DIR_NORTH = MyDirection_e(1)
  type(MyDirection_e), parameter :: DIR_SOUTH = MyDirection_e(2)
  type(MyDirection_e), parameter :: DIR_EAST  = MyDirection_e(3)
  type(MyDirection_e), parameter :: DIR_WEST  = MyDirection_e(4)
end module mod_my_directions

program test_forenum_program
  use mod_my_colors, only: MyColor_e, COLOR_RED, COLOR_GREEN, COLOR_BLUE
  use mod_my_directions, only: MyDirection_e, DIR_NORTH, DIR_EAST
  implicit none

  ! --- Test Variables ---
  type(MyColor_e) :: current_color, previous_color
  type(MyDirection_e) :: current_direction
  integer :: test_count = 0
  integer :: pass_count = 0

  ! --- Begin Tests ---
  write(*,*) "Starting Forenum Tests..."
  write(*,*) "========================="

  ! Test 1: Assignment
  current_color = COLOR_RED
  call check(current_color == COLOR_RED, "Assignment of COLOR_RED")

  previous_color = COLOR_BLUE
  call check(previous_color == COLOR_BLUE, "Assignment of COLOR_BLUE")

  current_direction = DIR_NORTH
  call check(current_direction == DIR_NORTH, "Assignment of DIR_NORTH")

  ! Test 2: Equality Comparison (Same Enum Type)
  call check(current_color == COLOR_RED, "Equality: current_color == COLOR_RED")
  call check(COLOR_GREEN == COLOR_GREEN, "Equality: COLOR_GREEN == COLOR_GREEN")

  ! Test 3: Inequality Comparison (Same Enum Type)
  call check(current_color /= COLOR_GREEN, "Inequality: current_color /= COLOR_GREEN")
  call check(previous_color /= COLOR_RED, "Inequality: previous_color /= COLOR_RED")
  call check(DIR_NORTH /= DIR_EAST, "Inequality: DIR_NORTH /= DIR_EAST")
  
  ! Test 4: Re-assignment and comparison
  current_color = COLOR_GREEN
  call check(current_color == COLOR_GREEN, "Re-assignment: current_color = COLOR_GREEN")
  call check(current_color /= COLOR_RED, "Inequality after re-assignment: current_color /= COLOR_RED")

  ! Test 5: Type Safety (Conceptual - relies on compiler)
  ! The following lines, if uncommented, should ideally cause a compile-time error
  ! because MyColor_e and MyDirection_e are different types.
  ! This demonstrates the type safety provided by forenum.
  !
  ! if (COLOR_RED == DIR_NORTH) then
  !   write(*,*) "TYPE SAFETY FAIL: COLOR_RED == DIR_NORTH (This should not compile)"
  ! else
  !   write(*,*) "TYPE SAFETY (conceptual): Compiler would prevent comparison of different enum types."
  ! end if
  !
  ! We can't directly test a compile error in a runtime script,
  ! but we acknowledge this is a key feature.
  write(*,*) ""
  write(*,*) "Note: Type safety (e.g., preventing comparison of MyColor_e with MyDirection_e)"
  write(*,*) "is enforced by the Fortran compiler at compile time, which is a core benefit."
  write(*,*) ""

  ! --- Test Summary ---
  write(*,*) "========================="
  write(*, '(A, I0, A, I0, A)') "Tests completed: ", pass_count, "/", test_count, " passed."
  if (pass_count == test_count) then
    write(*,*) "All Forenum tests passed successfully!"
  else
    write(*,*) "Some Forenum tests FAILED."
  end if
  write(*,*) "========================="

contains
  ! --- Helper Subroutine for Printing Test Results ---
  subroutine check(condition, test_name)
    logical, intent(in) :: condition
    character(len=*), intent(in) :: test_name
    
    test_count = test_count + 1
    write(*, '(A, I0, A, A, A)') "Test ", test_count, ": ", test_name, " - " ! Restored clearer format string
    if (condition) then
      write(*, '(A)') "PASS"
      pass_count = pass_count + 1
    else
      write(*, '(A)') "FAIL"
    end if
  end subroutine check
end program test_forenum_program