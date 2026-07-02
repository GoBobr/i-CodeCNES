subroutine mysub(a)
  integer :: a
  100 format(I4)
  a = a + 1
  write(*,100) a
end subroutine mysub
