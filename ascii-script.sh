# Running a series of shell commands directly in a workflow can quickly become messy. By placing your commands in a standalone script file and invoking it in one step, you maintain a clean, maintainable workflow.

sudo apt-get install cowsay -y
cowsay -f dragon "Run for cover, I am a DRAGON...RAWR" >> dragon.txt
grep -i "dragon" dragon.txt
cat dragon.txt
ls