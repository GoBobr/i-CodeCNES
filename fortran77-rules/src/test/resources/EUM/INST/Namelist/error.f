      program essai
      integer a, b
      namelist /mylist/ a, b
      a = 1
      b = 2
      write(*, nml=mylist)
      end
