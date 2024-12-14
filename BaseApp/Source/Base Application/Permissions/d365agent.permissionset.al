// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Agents;

/// <summary>
/// Provides basic access to the agent functionality. 
/// TODO: Move permission set to the System app Agent module when it is introduced
/// </summary>
permissionset 6219 "D365 Agent"
{
    Caption = 'Dynamics 365 Agent';
    Assignable = false;
    Permissions = tabledata Agent = Rimd,
                  tabledata "Agent Task" = RIMd,
                  tabledata "Agent Task File" = RIMd,
                  tabledata "Agent Task Message" = RIMd,
                  tabledata "Agent Task Message Attachment" = RIMD,
                  tabledata "Agent Access Control" = RIMD,
                  tabledata "Agent Task Pane Entry" = Rimd,
                  tabledata "Agent Task Step" = RIMd,
                  tabledata "Agent Task Timeline Entry" = Rimd,
                  tabledata "Agent Task Timeline Entry Step" = Rimd,
                  tabledata "Agent Task User Int Suggestion" = Rimd,
                  system "Manage Agent Tasks" = X;
}