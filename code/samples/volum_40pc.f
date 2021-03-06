      subroutine volum_40pc(iseed)
C     Determining the Luminosity Function of 40 pc,using criteria from
C     (Limoges et al. 2015)
C     Restrictions:
C        declination>0 Nort-Hemisphere SUPERBLINK survey
C        properMotion>40 mas/yr-1
C        V band limit: V<19
C     Method:
C        Number density per pc^3 and half bolometric magnitude
C        No 1/Vmax correction applied
C-------------------------------------------------------------------
C     ---   Parameters  ---
C     TODO: fill in 
C=======================================================================
      implicit double precision (a-h,m,o-z)
      external ran
      real ran

C     NOTE:too many variables. whole subr needs to be splited
      integer i,j,iseed
      integer numberOfStars,numberOfWDs
      integer eleminatedByParallax,eleminatedByDeclination,
     &        eleminatedByProperMotion,eleminatedByApparentMagn,
     &        eleminatedByReducedPropM
      double precision parameterIFMR
      double precision minimumProperMotion,declinationLimit,
     &                 minimumParallax
      double precision mbolmin,mbolinc,mbolmax      
      double precision hrm,gz
      double precision errinfa,errsupa,mbol
      double precision fnora,fnor,pi,rg,vvv,x,xx,xya
      
      parameter (numberOfStars=6000000)
C     (Only northern hemisphere)
      parameter (declinationLimit=0.0)
C     Minimum parallax below which we discard results (0.025<=>40 pc)
      parameter (minimumParallax=0.025)
C     Binning of Luminosity Function 
      parameter (mbolmin=5.75,mbolmax=20.75,mbolinc=0.5)
C     Minimum proper motion
      parameter (minimumProperMotion=0.04)
C     Parameters of mass histograms
      parameter (xmasi=0.1)
      parameter (xmasf=1.4)
      parameter (xmasinc=0.05)

      double precision properMotion(numberOfStars),
     &                 rightAscension(numberOfStars),
     &                 declination(numberOfStars)
      double precision luminosityOfWD(numberOfStars),
     &                 massOfWD(numberOfStars),
     &                 metallicityOfWD(numberOfStars),
     &                 effTempOfWD(numberOfStars)
      double precision flagOfWD(numberOfStars)
C     rgac - galactocentric distance to WD TODO: give a better name
      double precision rgac(numberOfStars)
      double precision coolingTime(numberOfStars)
C     NOTE: this 70 comes from nowhere      
      integer numberOfWDsInBin(70),numberOfBins
      double precision coordinate_R(numberOfStars),
     &                 coordinate_Theta(numberOfStars),
     &                 coordinate_Zcylindr(numberOfStars)
      double precision parallax(numberOfStars)
      double precision tangenVelo(numberOfStars)
      double precision errora(70),ndfa(70)
C     ugriz-color system and V-band from Johnson system
      double precision go(numberOfStars),gr(numberOfStars),
     &                 v(numberOfStars)
      double precision gi(numberOfStars),ur(numberOfStars),
     &                 rz(numberOfStars)
      double precision massInBin(70)
      double precision typeOfWD(numberOfStars)
C     values of LF in each bin. o-observational
      double precision xfl(19),xflo(19),xflcut(3),xflocut(3)
      double precision xflhot(11),xflohot(11)
C     bins for max-region: for synthetic and observational samples
      double precision xflMaxRegion(6), xfloMaxRegion(6)
C     number of WDs in bin of mass histogram
      double precision nbinmass(26)
C     WDs velocities. QUESTION: relative to what?
      double precision uu(numberOfStars), vv(numberOfStars), 
     &                 ww(numberOfStars)
C     sum of WDs velocities in specific bin, _u/_v/_w - components
      double precision sumOfWDVelocitiesInBin_u(70),
     &                 sumOfWDVelocitiesInBin_v(70),
     &                 sumOfWDVelocitiesInBin_w(70)
C     average velocity for WDs in specific bin      
      double precision averageWDVelocityInBin_u(70),
     &                 averageWDVelocityInBin_v(70),
     &                 averageWDVelocityInBin_w(70)  
C     this is used to calculate sigma (SD)
      double precision sumOfSquareDifferences_u,
     &                 sumOfSquareDifferences_v,
     &                 sumOfSquareDifferences_w
C     SD for velocities in each bin
      double precision standardDeviation_u(70),standardDeviation_v(70),
     &                 standardDeviation_w(70) 
C     2D-array of velocities (nº of bin; newly assigned to WD nº in bin)
C     needed to calculate Standart Deviation (SD) for velocities in each 
C     bin
C     TODO: make dinamic array or linked list
      double precision arrayOfVelocitiesForSD_u(25,50000)
      double precision arrayOfVelocitiesForSD_v(25,50000)
      double precision arrayOfVelocitiesForSD_w(25,50000)
C     2D-array of bolometric magnitudes for each WD; indexes are the 
C     same as for arrayOfVelocitiesForSD_u/v/w. (For cloud)
      double precision arrayOfMagnitudes(25,50000)


C     TODO: make a WD-class with these args
      common /enanas/ luminosityOfWD,massOfWD,metallicityOfWD,
     &                effTempOfWD
      common /index/ flagOfWD,numberOfWDs      
      common /mad/ properMotion,rightAscension,declination
      common /paral/ rgac
      common /coorcil/ coordinate_R,coordinate_Theta,coordinate_Zcylindr
      common /cool/ coolingTime
      common /photo/ go,gr,gi,ur,rz
      common /indexdb/ typeOfWD
      common /johnson/ V
      common /param/ fractionOfDB,galacticDiskAge,parameterIMF,
     &               parameterIFMR,timeOfBurst
      common /vel/ uu,vv,ww
     

      pi=4.0*atan(1.0d0)
      numberOfBins=(mbolmax-mbolmin)/mbolinc

C     TODO: remove unnecessary links
      do 1 i=1,70
        ndfa(i)=0.0d0
        numberOfWDsInBin(i)=0
        massInBin(i)=0.0
        sumOfWDVelocitiesInBin_u(i)=0.0
        sumOfWDVelocitiesInBin_v(i)=0.0
        sumOfWDVelocitiesInBin_w(i)=0.0
        averageWDVelocityInBin_u(i)=0.0
        averageWDVelocityInBin_v(i)=0.0
        averageWDVelocityInBin_w(i)=0.0
 1    continue

      do 2 i=1,26
        nbinmass(i)=0
 2    continue

      eleminatedByParallax=0
      eleminatedByDeclination=0
      eleminatedByReducedPropM=0
      eleminatedByProperMotion=0
      eleminatedByApparentMagn=0
           

C     ---  Eleminating WD's from the sample by restrictions  ---
C-----------------------------------------------------------------------
      do 5 i=1,numberOfWDs
        rg=rgac(i)*1000.0
        parallax(i)=1.0/rg
        tangenVelo(i)=4.74*properMotion(i)*rg
C       TODO: make signals warning about skipping steps
C        go to 93212
C       ---  1) Eliminate WDs with parallax<minimumParallax 
        if (parallax(i).lt.minimumParallax) then   
          eleminatedByParallax=eleminatedByParallax+1
C         QUESTION: can I avoid all these goto's?          
          go to 5
        end if

C       ---  2) Eliminate by declination  ---          
        if (declination(i).lt.declinationLimit) then   
          eleminatedByDeclination=eleminatedByDeclination+1
          go to 5        
        end if
C        goto 93212
C       ---  3) Eleminating too fast WD's  ---
C        if (sqrt(uu(i)**2+vv(i)**2+ww(i)**2) .ge. 500.0) then
C          go to 5
C        end if 

C       ---  4) Minimum proper motion cut  --- 
        if (properMotion(i).lt.minimumProperMotion) then   
          eleminatedByProperMotion=eleminatedByProperMotion+1
          go to 5  
        end if

C       ---  5) Reduced proper motion  ---
        hrm=go(i)+5.0*dlog10(properMotion(i))+5.0
        gz=gr(i)+rz(i)
        if(gz.lt.-0.33) then
          if(hrm.lt.14.0) then 
            eleminatedByReducedPropM=eleminatedByReducedPropM+1
            go to 5
          endif
        else 
          if(hrm.lt.(3.559*gz+15.17)) then
            if(v(i).gt.12.0) then
              xxx=ran(iseed)
            endif
            go to 5
            eleminatedByReducedPropM=eleminatedByReducedPropM+1
          endif
        endif
 453    write (160,*) 2.5*luminosityOfWD(i)+4.75,rgac(i)  

C       QUESTION: what does it mean? 
C       ---  6) Restriction V (de momento lo hacemos con go)  ---
        if(v(i).ge.19.0) then 
          eleminatedByApparentMagn=eleminatedByApparentMagn+1
          goto 5
        endif      
C       4    5    6   7   8   9            
C       Mbol Gap0 g-i g-r u-r r-z  
93212   write(156,*)  massOfWD(i),luminosityOfWD(i),metallicityOfWD(i),
     &    2.5*luminosityOfWD(i)+4.75,go(i),gi(i),gr(i),ur(i),rz(i),
     &    rightAscension(i),declination(i),rgac(i),parallax(i),
     &    properMotion(i),tangenVelo(i),coolingTime(i),effTempOfWD(i),
     &    typeOfWD(i),coordinate_Zcylindr(i),uu(i),vv(i),ww(i)
      continue

C     --- Making radial velocities zeroes  ---
C     ------------------------------------------------------------------
C      call vrado(uu,vv,ww)


C     TODO: place this in separate subroutine
C     ---  Making histogram of the mass---
C     ------------------------------------------------------------------
      K=0
  40  k=k+1 
      
      xi=xmasi+dfloat(k-1)*xmasinc
      xf=xi+xmasinc
      if(massOfWD(i).gt.xi.and.massOfWD(i).lt.xf) then 
        nbinmass(k)=nbinmass(k)+1
        goto 41
      else
        goto 40
      endif

C     ---   Calculating the luminosity function--- 

C     QUESTION: what does it mean?
C     ---   Calculos de turno varios  ---
 41   j=0
      mbol=2.5*luminosityOfWD(i) + 4.75 
4     j=j+1

C     ---   Calculating luminosity function of the WD's---
      if (mbol.le.mbolmin+mbolinc*dfloat(j).and.mbol.ge.mbolmin) then
C         NOTE: useless - use numberOfWDsInBin instead          
          ndfa(j)=ndfa(j)+1
          numberOfWDsInBin(j)=numberOfWDsInBin(j)+1
          massInBin(j)=massInBin(j)+massOfWD(i)
C         calculating sum of velocities of WD in bin Nºj (only from 
C         restricted sample). We will need it for calculating average 
C         velocities of WD for each bin (only from restricted sample)
          sumOfWDVelocitiesInBin_u(j)=sumOfWDVelocitiesInBin_u(j)+uu(i)
          sumOfWDVelocitiesInBin_v(j)=sumOfWDVelocitiesInBin_v(j)+vv(i)
          sumOfWDVelocitiesInBin_w(j)=sumOfWDVelocitiesInBin_w(j)+ww(i)
C         filling arrays of velocites for calculating SD
          arrayOfVelocitiesForSD_u(j,numberOfWDsInBin(j))=uu(i)
          arrayOfVelocitiesForSD_v(j,numberOfWDsInBin(j))=vv(i)
          arrayOfVelocitiesForSD_w(j,numberOfWDsInBin(j))=ww(i)
C         filling array of bolometric magnitudes for each WD in restr.s.
          arrayOfMagnitudes(j,numberOfWDsInBin(j))=mbol
      else 
        if (j.eq.numberOfBins) then
          goto 5
        endif
        goto 4
      endif
5     continue

C     NOTE that next loops can be put in one
C     NOTE I need to make subroutines and not to mix all this
      do 50 j=1,numberOfBins
C       calculating average velocities of WD for each bin (only from 
C       restricted sample) 
        if (numberOfWDsInBin(j) .ne. 0) then
          averageWDVelocityInBin_u(j)=sumOfWDVelocitiesInBin_u(j)/
     &    numberOfWDsInBin(j)
          averageWDVelocityInBin_v(j)=sumOfWDVelocitiesInBin_v(j)/
     &    numberOfWDsInBin(j)
          averageWDVelocityInBin_w(j)=sumOfWDVelocitiesInBin_w(j)/
     &    numberOfWDsInBin(j)
        
C         calculating Standart Deviation for velocities in each bin
C         TODO: place all this code for SD in subroutine
          sumOfSquareDifferences_u = 0.0
          sumOfSquareDifferences_v = 0.0
          sumOfSquareDifferences_w = 0.0
          do 51 i=1,numberOfWDsInBin(j)
            sumOfSquareDifferences_u=sumOfSquareDifferences_u+
     &                               (arrayOfVelocitiesForSD_u(j,i)-
     &                               averageWDVelocityInBin_u(j))**2
            sumOfSquareDifferences_v=sumOfSquareDifferences_v+
     &                               (arrayOfVelocitiesForSD_v(j,i)-
     &                               averageWDVelocityInBin_v(j))**2
            sumOfSquareDifferences_w=sumOfSquareDifferences_w+
     &                              (arrayOfVelocitiesForSD_w(j,i)-
     &                               averageWDVelocityInBin_w(j))**2
            write(815,444) arrayOfVelocitiesForSD_u(j,i), 
     &                     arrayOfVelocitiesForSD_v(j,i), 
     &                     arrayOfVelocitiesForSD_w(j,i), 
     &                     arrayOfMagnitudes(j,i)
51        continue
          if (numberOfWDsInBin(j) .ne. 1) then
            standardDeviation_u(j)=(sumOfSquareDifferences_u/
     &                             dfloat(numberOfWDsInBin(j))-1.0)**0.5
            standardDeviation_v(j)=(sumOfSquareDifferences_v/
     &                             dfloat(numberOfWDsInBin(j))-1.0)**0.5
            standardDeviation_w(j)=(sumOfSquareDifferences_w/
     &                             dfloat(numberOfWDsInBin(j))-1.0)**0.5
          else
            standardDeviation_u(j)=100.0
            standardDeviation_v(j)=100.0
            standardDeviation_w(j)=100.0
          endif
        endif
50    continue


C     ---  Write data of the LF of the WD's
C-----------------------------------------------------------------------
C     NOTE: this loop doesn't make any sense as ndfa cant be less than 0      
      do 6 i=1,numberOfBins
        if (ndfa(i).le.0.0) then
          ndfa(i)=10.0d-40
        endif 
6     continue

C     --- Volume of "North Hemisphere" in 40 pc ----
C          V_NH(40 pc)=134041.29
C     normalizing to the bins n=16+17+18, total 220 objects
C       n=17 is lum=-3.8 Mbol=14.25 with 72 objetos       
C     NOTE: better use numberOfWDsInBin here      
      fnor=(ndfa(16)+ndfa(17)+ndfa(18))/220.0
      fnora=(134041.29*fnor) 
      write (6,*) 'Factor de normalización:', fnor

C     ---   Recalculating LF   ---
C     QUESTION: what does it mean?
C     ojo factor norma
      do 71 i=1,numberOfBins
        ndfa(i)=ndfa(i)/fnora
71    continue

      do 7 i=1,numberOfBins
C       ---   Calculating error bars final touches  ---
C       old definition of binning
        x=mbolmin+(mbolinc)*dfloat(i)
C       new definition of binning -- when changing, go to BINNING WDLF 
C       and check the values
C        x=mbolmin+(mbolinc)*dfloat(i)-mbolinc/2.0
C       QUESTION: Why is this line here?
        xx=(x-4.75)/2.5
      
        if (numberOfWDsInBin(i) .eq. 0) then
          xya=0.0d0
          errsupa=0.0d0
          errinfa=0.0d0
          go to 9
        end if 
      
        xya=dlog10(ndfa(i))
C       NOTE: errora was never properly initialized!        
        errsupa=dlog10(ndfa(i)+errora(i))-xya
        if (numberOfWDsInBin(i).eq.1) then
          errinfa=-25.0
        else
          errinfa=dlog10(ndfa(i)-errora(i))-xya
        endif

        vvv=0.000
        massInBin(i)=massInBin(i)/dfloat(numberOfWDsInBin(i))
      
C       NOTE vvv is always 0      
9       write(155,200) vvv,xx,xya,errsupa,errinfa,numberOfWDsInBin(i),i,
     &                 averageWDVelocityInBin_u(i),
     &                 averageWDVelocityInBin_v(i),
     &                 averageWDVelocityInBin_w(i),
     &                 standardDeviation_u(i),standardDeviation_v(i),
     &                 standardDeviation_w(i)
        write(161,*) xx,massInBin(i),numberOfWDsInBin(i)

7     continue     


C     --- Writing data of histogram of masses ---
C-----------------------------------------------------------------------
      ntotmass=0
      do 80 i=1,26
        ntotmass=ntotmass+nbinmass(i)
 80   continue

      do 8 iii=1,26
        xxb=dfloat(ntotmass)
        write(162 ,*) xmasi+xmasinc*(dfloat(iii)-0.5),nbinmass(iii)/xxb
 8    continue

C     ---  Reading the LF teoretical/observational for performing chi² 
C          test ---
C-----------------------------------------------------------------------
C     LF global bins i=1,19; k=i+3
C     LF fit cutoff, 3 last bins
C     LF hot, 11 bins hot ones
C     LF global 
      do 10 i=1,19
        k=i+3
        xfl(i)=ndfa(k)*134041.29
        read (71,*) a1,i2
        xflo(i)=dfloat(i2)
        write (6,*) i,xfl(i),xflo(i)
  10  continue
       
      xflcut(1)=xfl(17)
      xflcut(2)=xfl(18)
      xflcut(3)=xfl(19)
      xflocut(1)=xflo(17)
      xflocut(2)=xflo(18)
      xflocut(3)=xflo(19)

      do 12 i=1,11
        xflhot(i)=xfl(i)
        xflohot(i)=xflo(i)
  12  continue

C     choosing region of maximum for calculating chi^2
      do 13 i=1,6
        xflMaxRegion(i)=xfl(i+11)
        xfloMaxRegion(i)=xflo(i+11)
  13  continue

      call chstwo(xfl,xflo,19,0,df,chsq,prob)
      write (6,*) '----------- Chi2 global LF-------------'
      write(6,*) 'df=',df
      write(6,*) 'chsq=',chsq
      write(6,*) 'prob=',prob
      write (6,*) '----------------------------------'

      OPEN (UNIT=20, STATUS='OLD',ACCESS = 'APPEND',
     &     file='./output_data/chisquare_test.out')
      write (20,222) fractionOfDB,galacticDiskAge,parameterIMF,
     &               parameterIFMR,timeOfBurst,df,chsq,prob
      CLOSE (22)

      call chstwo(xflhot,xflohot,11,0,df,chsq,prob)
      write (6,*) '----------- Chi2 HOT branch-------------'
      write(6,*) 'df=',df
      write(6,*) 'chsq=',chsq
      write(6,*) 'prob=',prob
      write (6,*) '----------------------------------'

      call chstwo(xflcut,xflocut,3,0,df,chsq,prob)
      write (6,*) '----------- Chi2 cut-off----------------'
      write(6,*) 'df=',df
      write(6,*) 'chsq=',chsq
      write(6,*) 'prob=',prob
      write (6,*) '----------------------------------'

      call chstwo(xflMaxRegion,xfloMaxRegion,6,0,df,chsq,prob)
      write (6,*) '----------- Chi2 maximum-region---------'
      write(6,*) 'df=',df
      write(6,*) 'chsq=',chsq
      write(6,*) 'prob=',prob
      write (6,*) '----------------------------------'
C     output for chi² of maximum-region vs galactic disk age - test
      OPEN (UNIT=30, STATUS='OLD',ACCESS = 'APPEND',
     &     file='./output_data/chi_sq_test_maxregion.out')
      write (30,333) galacticDiskAge,chsq,prob
      CLOSE (30)

 222   format(6(f6.3,1x),f6.2,1x,f7.4)
 333   format(f4.1,2x,f8.4,2x,f8.4)
 444   format(3(f7.2,2x),f6.3)

C-----------------------------------------------------------------------
             
      write(6,*) 'Initial number of WDs:               ',numberOfWDs
      write(6,*) 'Eliminated by parallax:              ',
     &eleminatedByParallax
      write(6,*) '    "       "       declination:     ',
     &eleminatedByDeclination
      write(6,*) 'Initial number northern hemisphere:  ',numberOfWDs-
     &eleminatedByParallax-eleminatedByDeclination
      write(6,*) '    "       " proper motion:         ',
     &eleminatedByProperMotion
      write(6,*) '    "       " reduced proper motion: ',
     &eleminatedByReducedPropM
      write(6,*) '    "       " apparent magnitude:    ',
     &eleminatedByApparentMagn
      write(6,*) 'Restricted sample           :        ',numberOfWDs-
     &eleminatedByParallax-eleminatedByDeclination-
     &eleminatedByProperMotion-eleminatedByReducedPropM-
     &eleminatedByApparentMagn

200   format(f6.3,2x,f6.3,2x,3(1pd14.7,2x),i4,i4,2x,6(1pd14.7,2x))

      return
      end