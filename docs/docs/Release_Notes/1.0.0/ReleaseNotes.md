# DXI 1.0.0 Release Notes

To install dxi, refer to [Getting started](/GettingStarted/index.html)

###Features
Dxi 1.0.0 release is the first release of the dxi.  
We are introducing both a Python Library and Python-based CLI.  

###Supported versions

The current release supports  

- Python 3.7 or above  
- macOS 10.15+  
- Windows 10  
- Delphix Engine 5.3.9 or above  

Future releases may add support for additional OS platforms and Delphix Engine versions.  

###Forward compatibility

Dxi Library and CLIs use Delphix Virtualization APIs as the point of orchestration for all Delphix operations.
Our long term strategic plan as a company is to build a New API Layer  that is simple and easy for end users to consume. This New API Layer will eventually become the single point of orchestration for all Delphix automation operations in future.

The New API Layer may also come with its own client library & CLI with functionality that 
overlaps dxi

Although we will encourage users to use the API Gateway once available, 
we will continue to support dxi in the foreseeable future.

We may also build future versions of dxi that support the New API Layer. 
However, forward compatibility between the current versions of dxi ( using Delphix Virtualization APIs) and the future versions ( using New API Layer )  is not guaranteed.

We also intended to make the migration from dxi to the New API Layer 
solution easier for our users by either automating the process to make it transparent to dxi users or help them update their code.

However,   

- Forward compatibility is not guaranteed between current versions of dxi ( that use virtualization apis) and future versions of dxi ( that use New API Layer)
- Forward compatibility is not guaranteed between dxi and the New API Layer solution

As such, it is possible that manual work may be required for migration to a future version/solution.


Questions?
----------------
If you have questions, bugs or feature requests reach out to us via [email](dxi-support@delphix.com)