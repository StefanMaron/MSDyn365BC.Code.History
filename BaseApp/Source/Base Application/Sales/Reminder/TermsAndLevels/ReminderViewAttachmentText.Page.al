// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 839 "Reminder View Attachment Text"
{
    PageType = ListPart;
    SourceTable = "Reminder Attachment Text";
    Caption = 'Attachment Text';
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                ShowCaption = false;
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'Language Code';
                    ToolTip = 'Specifies the language code for the text communications.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    Caption = 'File Name';
                    ToolTip = 'Specifies the file name of the attachment.';
                }
                field("Inline Fee Description"; Rec."Inline Fee Description")
                {
                    ApplicationArea = All;
                    Caption = 'Inline Fee Description';
                    ToolTip = 'Specifies the description line that will appear in the attachment along side the fee.';
                }
                field("Beginning Line"; Rec."Beginning Line")
                {
                    ApplicationArea = All;
                    Caption = 'Beginning Line';
                    ToolTip = 'Specifies the first line of the attachment.';
                }
                field("Ending Line"; Rec."Ending Line")
                {
                    ApplicationArea = All;
                    Caption = 'Ending Line';
                    ToolTip = 'Specifies the last line of the attachment.';
                }
            }
        }
    }
}