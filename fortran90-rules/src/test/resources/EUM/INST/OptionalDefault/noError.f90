subroutine mysub(a, b)
  integer :: a
  integer, optional :: b
  if (.not. present(b)) b = 0
  x = a + b
end subroutine mysub
