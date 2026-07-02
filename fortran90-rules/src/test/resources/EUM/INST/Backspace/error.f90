program essai
  integer :: i
  open(unit=10, file='test.dat')
  backspace(10)
  read(10,*) i
  close(10)
end program essai
