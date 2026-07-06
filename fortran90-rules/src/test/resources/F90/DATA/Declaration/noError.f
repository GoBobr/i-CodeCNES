program ESSAI

  implicit none

  INTEGER, parameter :: NbDim = 3
  INTEGER, parameter :: NbPoints = 5

  DOUBLE PRECISION, dimension(NbDim, NbPoints) :: Points
  DOUBLE PRECISION, dimension(NbDim)           :: Deplacement

! initialisation des tableaux 
  data Deplacement / 0.5, -2.5, 3.0 /
  Points = reshape((/ 0., 1., 2., 3., 4., 5., 6., 7., 8., 9., 10., 11., 12., 13., 14. /), shape(Points))

! impression sur sortie standard du contenu des tableaux
  print*, '-- tableau deplacement --', Deplacement
  print*, '-- tableau de points  --', Points

! traitement : on applique un deplacement sur les coordonnees des points 
  call changer_coordonnees(Deplacement, NbPoints, Points) 

! impression sur sortie standard du contenu des tableaux
  print*, '-- tableau de points (apres) --', Points
 
end program ESSAI

! 
! Cette routine effectue une modification de coordonnees sur un tableau de points 
!    en appliquant un deplacement  sur les 3 axes x, y et z
!
subroutine changer_coordonnees(Deplacement, NbPoints, Points)
	USE blabla
   IMPLICIT NONE

   INTEGER :: c
   INTEGER :: l

   INTEGER, parameter :: NbDim = 3
   INTEGER, intent(in) :: NbPoints

   DOUBLE PRECISION, intent(inout), dimension(NbDim,NbPoints) :: Points
   DOUBLE PRECISION, intent(in), dimension(NbDim) :: Deplacement

! On applique a chaque point une valeur de deplacement selon les 3 axes 
   do c=1, NbDim, 1
      do l=1, NbPoints, 1 
         Points(c, l) = Points(c, l) + Deplacement(c)
      end do 
   end do 

end subroutine

! Test: Fortran 2003 keywords in type definition should not be flagged
module keyword_test
  implicit none
  type, public :: my_type
    DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE :: values
  CONTAINS
    FINAL :: my_type_dealloc
    PROCEDURE :: my_type_assign
    GENERIC :: ASSIGNMENT(=) => my_type_assign
  END TYPE my_type

  PUBLIC :: safe_dealloc
  PUBLIC :: allocation_error

  CHARACTER(LEN=100), PUBLIC, PARAMETER :: allocation_error = "ALLOCATION ERROR"

contains
  subroutine safe_dealloc(arr)
    DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE :: arr
    if (allocated(arr)) deallocate(arr)
  end subroutine safe_dealloc

  subroutine my_type_dealloc(this)
    type(my_type) :: this
    if (allocated(this%values)) deallocate(this%values)
  end subroutine

  subroutine my_type_assign(lhs, rhs)
    type(my_type), intent(out) :: lhs
    type(my_type), intent(in) :: rhs
  end subroutine
end module keyword_test

! Test: D0/E0 numeric literals should not extract d0/e0 as variable names
module literal_test
  implicit none
  real(8) :: x
  x = 0.D0
  x = 1.0E0
  x = 1D0
  x = 0.5D+10
  if (x > 0.D0 .and. x < 1.D0) then
    x = 0.0D0
  end if
  select case (nint(x))
  case (0)
    x = 0.D0
  case default
    x = 1.D0
  end select
end module literal_test

! Test: USE without ONLY should not flag imported names as undeclared
module use_test
  use intrinsic_types_module
  implicit none
  integer :: ierr
  ierr = 0
  if (ierr /= 0) then
    ierr = 1
  end if
end module use_test

! Test: IMPLICIT NONE after USE, INTRINSIC
module intrinsic_test
  use, intrinsic :: iso_c_binding
  implicit none
  integer :: status
  status = 0
end module intrinsic_test

! Test: CLASS declarations
module class_test
  implicit none
  type, abstract :: base_type
  contains
    procedure(do_interface), deferred :: do_something
  end type base_type
  type, extends(base_type) :: concrete_type
    integer :: val
  contains
    procedure :: do_something => concrete_do
  end type concrete_type
  abstract interface
    subroutine do_interface(this)
      import :: base_type
      class(base_type) :: this
    end subroutine do_interface
  end interface
contains
  subroutine concrete_do(this)
    class(concrete_type) :: this
    this%val = 0
  end subroutine
end module class_test 

