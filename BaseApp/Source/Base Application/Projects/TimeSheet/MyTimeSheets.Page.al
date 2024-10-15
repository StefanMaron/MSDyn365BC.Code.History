// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 9155 "My Time Sheets"
{
    Caption = 'My Time Sheets';
    PageType = ListPart;
    SourceTable = "My Time Sheets";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Time Sheet No."; Rec."Time Sheet No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No.';
                    ToolTip = 'Specifies the number of the time sheet.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the assignment.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the assignment.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any comments about the assignment.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';

                trigger OnAction()
                begin
                    EditTimeSheet();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetTimeSheet();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(TimeSheetHeader);
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    var
        TimeSheetHeader: Record "Time Sheet Header";

    local procedure GetTimeSheet()
    begin
        Clear(TimeSheetHeader);

        if TimeSheetHeader.Get(Rec."Time Sheet No.") then begin
            Rec."Time Sheet No." := TimeSheetHeader."No.";
            Rec."Start Date" := TimeSheetHeader."Starting Date";
            Rec."End Date" := TimeSheetHeader."Ending Date";
            Rec.Comment := TimeSheetHeader.Comment;
        end;
    end;

    local procedure EditTimeSheet()
    begin
        TimeSheetHeader.Get(Rec."Time Sheet No.");
        Page.Run(Page::"Time Sheet Card", TimeSheetHeader);
    end;
}

