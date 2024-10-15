// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

dotnet
{
    assembly("Microsoft.Dynamics.Nav.PermissionTestHelper")
    {
        Version = '21.0.0.0';
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.Runtime.PermissionTestHelper"; "PermissionTestHelper")
        {
        }
    }

    assembly(System.Security.Principal.Windows)
    {
        type("System.Security.Principal.WindowsIdentity"; "System.Security.Principal.WindowsIdentity")
        {
        }

        type("System.Security.Principal.SecurityIdentifier"; "System.Security.Principal.SecurityIdentifier")
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

    assembly("netstandard")
    {
        type("System.Reflection.BindingFlags"; "System.Reflection.BindingFlags")
        {
        }

        type("System.Security.Cryptography.AsymmetricAlgorithm"; "AsymmetricAlgorithm")
        {
        }

        type("System.UnauthorizedAccessException"; "System.UnauthorizedAccessException")
        {
        }
        type("System.Diagnostics.ProcessStartInfo"; "System.Diagnostics.ProcessStartInfo")
        {
        }

        type("System.Net.Mail.MailMessage"; "System.Net.Mail.MailMessage")
        {
        }
        type("System.Net.Http.HttpRequestMessage"; "HttpRequestMessage")
        {
        }
        type("System.Xml.XmlException"; "System.Xml.XmlException")
        {
        }

        type("System.Xml.Schema.XmlSchema"; "System.Xml.Schema.XmlSchema")
        {
        }

        type("System.Xml.Schema.ValidationEventHandler"; "System.Xml.Schema.ValidationEventHandler")
        {
        }
        type("System.Collections.ObjectModel.Collection`1"; "Collection1")
        {
        }
    }
}

