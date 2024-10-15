// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN22
namespace Microsoft.Inventory.Intrastat;

using System.Reflection;

page 325 "Intrastat Journal Templates"
{
    ApplicationArea = BasicEU;
    Caption = 'Intrastat Journal Templates';
    PageType = List;
    SourceTable = "Intrastat Jnl. Template";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the name of the Intrastat journal template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a description of the Intrastat journal template.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = BasicEU;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = BasicEU;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Checklist Report ID"; Rec."Checklist Report ID")
                {
                    ApplicationArea = BasicEU;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the checklist that can be printed if you click Actions, Print in the Intrastat journal window and then select Checklist Report.';
                    Visible = false;
                }
                field("Checklist Report Caption"; Rec."Checklist Report Caption")
                {
                    ApplicationArea = BasicEU;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the test report that you can print.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action(Batches)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "Intrastat Jnl. Batches";
                    RunPageLink = "Journal Template Name" = field(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                    Scope = Repeater;
                }
            }
        }
        area(Promoted)
        {
            actionref("Batches_Promoted"; Batches)
            {

            }
        }
    }
}
#endif
