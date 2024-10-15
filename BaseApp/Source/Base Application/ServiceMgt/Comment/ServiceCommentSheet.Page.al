namespace Microsoft.Service.Comment;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;

page 5911 "Service Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Service Comment Sheet';
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Service Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date you entered the service comment.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the service comment.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := CopyStr(Caption() + CaptionString, 1, 80);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;

    trigger OnOpenPage()
    begin
        CaptionString := CurrPage.Caption;
    end;

    var
        CaptionString: Text[80];

    procedure Caption(): Text
    var
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        ServContractLine: Record "Service Contract Line";
        ServContract: Record "Service Contract Header";
        ServCommentLine: Record "Service Comment Line";
        ServItem: Record "Service Item";
        Loaner: Record Loaner;
    begin
        Clear(ServCommentLine);
        if Rec.GetFilter("Table Name") <> '' then
            Evaluate(ServCommentLine."Table Name", Rec.GetFilter("Table Name"));

        if Rec.GetFilter("Table Subtype") <> '' then
            Evaluate(ServCommentLine."Table Subtype", Rec.GetFilter("Table Subtype"));

        if Rec.GetFilter("No.") <> '' then
            Evaluate(ServCommentLine."No.", Rec.GetFilter("No."));

        if Rec.GetFilter(Type) <> '' then
            Evaluate(ServCommentLine.Type, Rec.GetFilter(Type));

        if Rec.GetFilter("Table Line No.") <> '' then
            Evaluate(ServCommentLine."Table Line No.", Rec.GetFilter("Table Line No."));

        if ServCommentLine."Table Line No." > 0 then
            if ServItemLine.Get(ServCommentLine."Table Subtype", ServCommentLine."No.", ServCommentLine."Table Line No.") then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServItemLine."Document Type", ServItemLine."Document No.",
                    ServItemLine.Description, ServCommentLine.Type));

        if ServCommentLine."Table Name" = ServCommentLine."Table Name"::"Service Header" then
            if ServHeader.Get(ServCommentLine."Table Subtype", ServCommentLine."No.") then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServHeader."Document Type", ServHeader."No.",
                    ServHeader.Description, ServCommentLine.Type));

        if ServCommentLine."Table Name" = ServCommentLine."Table Name"::"Service Contract" then
            if ServContractLine.Get(ServCommentLine."Table Subtype",
                 ServCommentLine."No.", ServCommentLine."Table Line No.")
            then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServContractLine."Contract Type", ServContractLine."Contract No.",
                    ServContractLine.Description, ServCommentLine.Type));

        if ServCommentLine."Table Name" = ServCommentLine."Table Name"::"Service Contract" then
            if ServContract.Get(ServCommentLine."Table Subtype", ServCommentLine."No.") then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServContract."Contract Type",
                    ServContract."Contract No.", ServContract.Description, ServCommentLine.Type));

        if ServCommentLine."Table Name" = ServCommentLine."Table Name"::"Service Item" then
            if ServItem.Get(ServCommentLine."No.") then
                exit(StrSubstNo('%1 %2 - %3 ', ServItem."No.", ServItem.Description, ServCommentLine.Type));

        if ServCommentLine."Table Name" = ServCommentLine."Table Name"::Loaner then
            if Loaner.Get(ServCommentLine."No.") then
                exit(StrSubstNo('%1 %2 - %3 ', Loaner."No.", Loaner.Description, ServCommentLine.Type));
    end;
}

