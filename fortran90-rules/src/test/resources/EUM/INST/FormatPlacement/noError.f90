subroutine mysub(a)
  integer :: a
  a = a + 1
  write(*,100) a
  100 format(I4)
end subroutine mysub
