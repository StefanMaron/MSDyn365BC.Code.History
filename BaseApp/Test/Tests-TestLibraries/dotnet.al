// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

dotnet
{
    assembly("Microsoft.Dynamics.Nav.PermissionTestHelper")
    {
        Version = '20.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.Runtime.PermissionTestHelper"; "PermissionTestHelper")
        {
        }
    }

    assembly(mscorlib)
    {

        type("System.Collections.ObjectModel.Collection`1"; "Collection1")
        {
        }

        type("System.Reflection.BindingFlags"; "System.Reflection.BindingFlags")
        {
        }

        type("System.Security.Cryptography.AsymmetricAlgorithm"; "AsymmetricAlgorithm")
        {
        }

        type("System.Security.Principal.WindowsIdentity"; "System.Security.Principal.WindowsIdentity")
        {
        }

        type("System.Security.Principal.SecurityIdentifier"; "System.Security.Principal.SecurityIdentifier")
        {
        }

        type("System.UnauthorizedAccessException"; "System.UnauthorizedAccessException")
        {
        }
    }

    assembly("System")
    {
        Version = '4.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = 'b77a5c561934e089';

        type("System.Diagnostics.ProcessStartInfo"; "System.Diagnostics.ProcessStartInfo")
        {
        }

        type("System.Net.Mail.MailMessage"; "System.Net.Mail.MailMessage")
        {
        }
    }

    assembly("System.DirectoryServices.AccountManagement")
    {
        Version = '4.0.0.0';

        type("System.DirectoryServices.AccountManagement.ContextType"; "System.DirectoryServices.AccountManagement.ContextType")
        {
        }

        type("System.DirectoryServices.AccountManagement.GroupPrincipal"; "System.DirectoryServices.AccountManagement.GroupPrincipal")
        {
        }

        type("System.DirectoryServices.AccountManagement.IdentityType"; "System.DirectoryServices.AccountManagement.IdentityType")
        {
        }

        type("System.DirectoryServices.AccountManagement.Principal"; "System.DirectoryServices.AccountManagement.Principal")
        {
        }

        type("System.DirectoryServices.AccountManagement.PrincipalContext"; "System.DirectoryServices.AccountManagement.PrincipalContext")
        {
        }
    }

    assembly("System.Management.Automation")
    {
        Version = '3.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("System.Management.Automation.PSCommand"; "System.Management.Automation.PSCommand")
        {
        }

        type("System.Management.Automation.PowerShell"; "System.Management.Automation.PowerShell")
        {
        }

        type("System.Management.Automation.Runspaces.Runspace"; "System.Management.Automation.RunSpaces.Runspace")
        {
        }

        type("System.Management.Automation.Runspaces.Pipeline"; "System.Management.Automation.Runspaces.Pipeline")
        {
        }

        type("System.Management.Automation.Runspaces.InitialSessionState"; "System.Management.Automation.Runspaces.InitialSessionState")
        {
        }

        type("System.Management.Automation.Runspaces.CommandCollection"; "System.Management.Automation.Runspaces.CommandCollection")
        {
        }

        type("System.Management.Automation.Runspaces.Command"; "System.Management.Automation.Runspaces.Command")
        {
        }
    }

    assembly("System.Net.Http")
    {
        Version = '4.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = 'b03f5f7f11d50a3a';

        type("System.Net.Http.HttpRequestMessage"; "HttpRequestMessage")
        {
        }
    }

    assembly("System.Xml")
    {
        Version = '4.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = 'b77a5c561934e089';

        type("System.Xml.XmlException"; "System.Xml.XmlException")
        {
        }

        type("System.Xml.Schema.XmlSchema"; "System.Xml.Schema.XmlSchema")
        {
        }

        type("System.Xml.Schema.ValidationEventHandler"; "System.Xml.Schema.ValidationEventHandler")
        {
        }
    }

    assembly("System.Windows.Forms")
    {
        Version = '4.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = 'b77a5c561934e089';

        type("System.Windows.Forms.Control"; "System.Windows.Forms.Control")
        {
        }
    }

}

