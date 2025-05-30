module forenum
  implicit none
  private

  public :: EnumBase_t

  ! Define integer kind for the internal storage of enum values.
  ! selected_int_kind(4) typically provides a 2-byte integer,
  ! supporting values up to +/- 9999. This kind is internal to mod_enum.
  integer, parameter :: enum_int_k = selected_int_kind(4)

  type, abstract :: EnumBase_t
    integer(kind=enum_int_k) :: enum_value
  contains
    procedure :: enums_are_equal
    procedure :: enums_are_not_equal
    generic :: operator(==) => enums_are_equal
    generic :: operator(/=) => enums_are_not_equal
  end type EnumBase_t

  !-----------------------------------------------------------------------------
  ! Example of how to define a specific enum type in another module using this base type:
  !-----------------------------------------------------------------------------
  ! module mod_my_custom_enums
  !   use mod_enum, only: EnumBase_t
  !   implicit none
  !   private
  !
  !   public :: MyColor_e
  !   public :: COLOR_RED, COLOR_GREEN, COLOR_BLUE
  !   
  !   ! Should use PascalCase_e for enum type names.
  !   type, extends(EnumBase_t) :: MyColor_e
  !     ! No additional components needed unless specific to this enum
  !   end type MyColor_e
  !
  !   ! Use plain integer literals for the values.
  !   ! The EnumBase_t constructor will handle the assignment to its internal 'enum_value'
  !   ! component, which is of kind 'enum_int_k' (defined in mod_enum).
  !   type(MyColor_e), parameter :: COLOR_RED   = MyColor_e(0)
  !   type(MyColor_e), parameter :: COLOR_GREEN = MyColor_e(1)
  !   type(MyColor_e), parameter :: COLOR_BLUE  = MyColor_e(2)
  !
  ! end module mod_my_custom_enums
  !-----------------------------------------------------------------------------

contains

  logical function enums_are_equal(this, other) result(is_equal)
    class(EnumBase_t), intent(in) :: this
    class(EnumBase_t), intent(in) :: other

    ! Check if the dynamic types are the same
    if (.not. same_type_as(this, other)) then
      write (*, '(A)') 'ERROR: [forenum.enums_are_equal] Attempting to compare enums of different types.'
      stop 1111 ! Stop with a non-zero status.
    end if

    is_equal = this % enum_value == other % enum_value
  end function enums_are_equal

  logical function enums_are_not_equal(this, other) result(is_not_equal)
    class(EnumBase_t), intent(in) :: this
    class(EnumBase_t), intent(in) :: other

    if (.not. same_type_as(this, other)) then
      write (*, '(A)') 'ERROR: [forenum.enums_are_not_equal] Attempting to compare enums of different types.'
      stop 2222 ! Stop with a non-zero status.
    end if
    is_not_equal = this % enum_value /= other % enum_value
  end function enums_are_not_equal

end module forenum
