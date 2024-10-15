// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Security.User;

page 710 "Activity Log"
{
    Caption = 'Activity Log';
    DelayedInsert = false;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Activity Log";
    SourceTableView = sorting("Activity Date")
                      order(descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Activity Date"; Rec."Activity Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the data of the activity.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field(Context; Rec.Context)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the context in which the activity occurred.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the activity.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the activity.';
                }
                field("Activity Message"; Rec."Activity Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status or error message for the activity.';
                }
                field(HasDetailedInfo; HasDetailedInfo)
                {
                    ApplicationArea = All;
                    Caption = 'Detailed Info Available';
                    ToolTip = 'Specifies if detailed activity log details exist. If so, choose the View Details action.';

                    trigger OnDrillDown()
                    begin
                        Rec.Export('', true);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OpenRelatedRecord)
            {
                ApplicationArea = Invoicing, Suite;
                Caption = 'Open Related Record';
                Image = View;
                ToolTip = 'Open the record that is associated with this activity.';

                trigger OnAction()
                var
                    PageManagement: Codeunit "Page Management";
                begin
                    if not PageManagement.PageRun(Rec."Record ID") then
                        Message(NoRelatedRecordMsg);
                end;
            }
            action(ViewDetails)
            {
                ApplicationArea = Invoicing, Suite;
                Caption = 'View Details';
                Ellipsis = true;
                Image = GetSourceDoc;
                ToolTip = 'Show more information about this activity.';

                trigger OnAction()
                begin
                    Rec.Export('', true);
                end;
            }
            action(Delete7days)
            {
                ApplicationArea = Invoicing, Suite;
                Caption = 'Delete Entries Older than 7 Days';
                Image = ClearLog;
                ToolTip = 'Removes entries that are older than 7 days from the log.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(7);
                end;
            }
            action(Delete0days)
            {
                ApplicationArea = Invoicing, Suite;
                Caption = 'Delete All Entries';
                Image = Delete;
                ToolTip = 'Empties the log. All entries will be deleted.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(0);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(OpenRelatedRecord_Promoted; OpenRelatedRecord)
                {
                }
                actionref(ViewDetails_Promoted; ViewDetails)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        HasDetailedInfo := Rec."Detailed Info".HasValue;
    end;

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
        Rec.SetAutoCalcFields("Detailed Info");
    end;

    var
        HasDetailedInfo: Boolean;
        NoRelatedRecordMsg: Label 'There are no related records to display.';
}

