// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 833 "Reminder Attachment Text"
{
    Caption = 'Attachment Texts';
    PageType = CardPart;
    SourceTable = "Reminder Attachment Text";
    Editable = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(AttachmentTexts)
            {
                ShowCaption = false;
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
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
                    Importance = Additional;
                    Caption = 'Beginning Line';
                    ToolTip = 'Specifies the first line of the attachment.';
                }
                field("Ending Line"; Rec."Ending Line")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Caption = 'Ending Line';
                    ToolTip = 'Specifies the last line of the attachment.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if LanguageCode = '' then
            exit;

        if not Rec.Get(Rec.Id, LanguageCode) then
            Error(NoAttachmentTextFoundErr, LanguageCode);
    end;

    var
        LanguageCode: Code[10];
        NoAttachmentTextFoundErr: Label 'No attachment text found for the selected language %1.', Comment = '%1 = Language code';

    internal procedure SetSourceData(SelectedLanguageCode: Code[10])
    begin
        LanguageCode := SelectedLanguageCode;
    end;
}