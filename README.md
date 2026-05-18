Inception of things
1. Part 1
   - 
     - 1
2. Part 2
3. Part 3
! Part 3 should run without VM. However, Bonus part requires a VM and it should run on top of Part 3. To save your time and avoid messing up your local machine, I recommend to build a VM in Bonus folder and run Part 3 in it. !
- cd bonus
- make build-vm
- vagrant ssh
- git clone https://github.com/darambae/inception-of-things-dabae.git
- cd inception-of-things-dabae/p3/scripts
- ./setup.sh
- cd ..
- make build
- make forward
- To be able to connect from host machine to the pods, make sure '192.168.56.10	gitlab.127.0.0.1.nip.io' set in /etc/hosts of your host computer.
- In your browser, enter 'http://192.168.56.10:8080/' to access the application in the pod and 'https://192.168.56.10:9443/' to access ArgoCD UI in another page
- Modify deployment.yaml file ('v1' -> 'v2') and synchronize ArgoCD
- Once its status turns healthy, reload the application page and check if 'v1' changes to 'v2'

4. Bonus
   1. How to test
    ! If you haven't built a VM, please set up the prerequisite following the step 1~8 of Part3 !
    - cd script
    - 