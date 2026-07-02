! NAME: mysub
! PURPOSE: This is a test subroutine.
subroutine mysub(a, b)
  integer, intent(in) :: a
  integer, intent(out) :: b
  b = a * 2
end subroutine mysub
