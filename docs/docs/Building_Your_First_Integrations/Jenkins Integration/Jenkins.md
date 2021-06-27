#Integrate using dxi cli


Now that you have installed and configured dxi, let us explore how we can integrate Delphix operations into workflows.
We will be using a sample Jenkins Pipeline as an example.

A Jenkins Pipeline Example 1
-------------------

Our first example here is a Jenkins Declarative Pipeline that runs a set of automated tests.
We want to integrate a VDB Snapshot operation and a VDB Rewind operation into this pipeline.
This pipeline has 3 steps - 

- Pre-Test : Sets up the test environment
- Automated Test1 : Runs a set of automation tests using a Delphix VDB named "vdb1"
- Post-Test: Tears down the test environment

![Screenshot](/image/pipeline1.png)

###Adding a Delphix Snapshot Operation

Let's say, we want to modify this pipeline such that it take a snapshot of the VDB <span class="data_highlight">(vdb1)</span> in Delphix before the tests run.
![Screenshot](/image/pipeline2.png)

For this we can use the <span class="data_highlight">dxi snapshot</span> cli command as follows

<div class="code_box_outer">
    <div class="code_box_title">
        <span class="code_title">Jenkins Pipeline Script</span>
    </div>
    <div>
        ```groovy hl_lines="6"
            pipeline {
              ...

              stage('VDB Snapshot') {
                  steps {
                    sh '/path/to/dxi database snapshot --name vdb1'
                  }
              }

              ...
            }
        ```
    </div>
</div>

###Adding a Delphix Rewind Operation

Next, we want to rewind the VDB <span class="data_highlight">(vdb1)</span> after the tests are run.
![Screenshot](/image/pipeline3.png)

For this we can use the <span class="data_highlight">dxi rewind</span> cli command as follows

<div class="code_box_outer">
    <div class="code_box_title">
        <span class="code_title">Jenkins Pipeline Script</span>
    </div>
    <div>
        ```groovy hl_lines="6 15"
            pipeline {
              ...

              stage('VDB Snapshot') {
                  steps {
                    sh '/path/to/dxi database snapshot --name vdb1'
                  }
              }
              ...
              stage('Automated Test 1') {  
              ...
              }
              stage('Rewind VDB') {
                  steps {
                    sh '/path/to/dxi database rewind --name vdb1'
                  }
              }
            }
        ```
    </div>
</div>


###The Finished Pipeline

![Screenshot](/image/pipeline4.png)

And you have now integrated Delphix Snapshot and Rewind operations into a Jenkins Pipeline.

A Jenkins Pipeline Example 2
-------------------

Our second example here is a Jenkins Declarative Pipeline that runs a series of automated tests, one after the other.  

We will use Delphix Self Service Containers (a group of VDBs) for this example as we want to create bookmarks between the different test executions.
These bookmarks are references to specific points in time on our container's timeline and can
be used to rewind our container to the timepoint referenced by the bookmark.

This pipeline has 4 staps -

- Pre-Test : Sets up the test environment
- Automated Test1 : Runs first set of automation tests using a Delphix Container named <span class="data_highlight">container1</span>
- Automated Test2 : Runs second set of automation tests using a Delphix Container named <span class="data_highlight">container1</span>
- Post-Test: Tears down the test environment

We will integrate the following Delphix Operations into this pipeline  

- Create a bookmark <span class="data_highlight">bmk-pre-test1</span> before Automated Test 1  
- Create a bookmark <span class="data_highlight">bmk-pre-test2</span> before Automated Test 2  
- Rewind the Container <span class="data-highlight">container1</span> to <span class="data_highlight">bmk-pre-test1</span> after Automation Test 2  

![Screenshot](/image/pipeline5.png)

###Adding the Container Bookmark Operations

We can use <span class="data_highlight">dxi bookmark</span> cli command as follows

<div class="code_box_outer">
    <div class="code_box_title">
        <span class="code_title">Jenkins Pipeline Script</span>
    </div>
    <div>
        ```groovy hl_lines="6 7 15 16"
            pipeline {
              ...

              stage('Create bmk-pre-test1') {
                  steps {
                    sh '/path/to/dxi  bookmark create
                            --bookmarkname bmk-pre-test1 --containername container1'
                  }
              }
              stage('Automated Test 2') {
                  ...
              }
              stage('Create bmk-pre-test2') {
                  steps {
                    sh '/path/to/dxi bookmark create
                            --bookmarkname bmk-pre-test2 --containername container1'
                  }
              }
              ...
            }
        ```
    </div>
</div>


###Adding the Container Restore Operations

Next, we want to rewind/restore the container <span class="data_highlight">container1</span> to <span class="data_highlight">bmk-pre-test2>/span>

For this we can use the <span class="data_highlight">dxi container</span> cli command as follows

<div class="code_box_outer">
    <div class="code_box_title">
        <span class="code_title">Jenkins Pipeline Script</span>
    </div>
    <div>
        ```groovy hl_lines="21 22"
            pipeline {
              ...

              stage('Create bmk-pre-test1') {
                  steps {
                    sh '/path/to/dxi bookmark create
                            --bookmarkname bmk-pre-test1 --containername container1'
                  }
              }
              stage('Automated Test 2') {
                  ...
              }
              stage('Create bmk-pre-test2') {
                  steps {
                    sh '/path/to/dxi bookmark create
                            --bookmarkname bmk-pre-test2 --containername container1'
                  }
              }
              stage('Restore to bmk-pre-test1') {
                  steps {
                    sh '/path/to/dxi container restore
                            --bookmark_name bmk-pre-test2 --container_name container1'
                  }
              }
              ...
            }
        ```
    </div>
</div>


###The Finished Pipeline

![Screenshot](/image/pipeline6.png)

And you have now integrated Delphix Self Service Container Operations into a Jenkins Pipeline.

##What's Next?
As you have seen, with dxi, integration of Delphix Operations into your workflows take only a few minutes.
For information on all supported Delphix operations, read our [References](/References/CLI_References/environment/index.html) section.
