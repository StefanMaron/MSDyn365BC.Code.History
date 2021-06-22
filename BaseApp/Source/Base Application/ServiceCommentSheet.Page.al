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
                field(Date; Date)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date you entered the service comment.';
                }
                field(Comment; Comment)
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
        CurrPage.Caption := CopyStr(Caption + CaptionString, 1, 80);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine;
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
        if GetFilter("Table Name") <> '' then
            Evaluate(ServCommentLine."Table Name", GetFilter("Table Name"));

        if GetFilter("Table Subtype") <> '' then
            Evaluate(ServCommentLine."Table Subtype", GetFilter("Table Subtype"));

        if GetFilter("No.") <> '' then
            Evaluate(ServCommentLine."No.", GetFilter("No."));

        if GetFilter(Type) <> '' then
            Evaluate(ServCommentLine.Type, GetFilter(Type));

        if GetFilter("Table Line No.") <> '' then
            Evaluate(ServCommentLine."Table Line No.", GetFilter("Table Line No."));

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

        if ServCommentLine."Table Name" = ServCommentLine."Table Name"::"Service Contract" then begin
            if ServContractLine.Get(ServCommentLine."Table Subtype",
                 ServCommentLine."No.", ServCommentLine."Table Line No.")
            then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServContractLine."Contract Type", ServContractLine."Contract No.",
                    ServContractLine.Description, ServCommentLine.Type));
        end;

        if ServCommentLine."Table Name" = ServCommentLine."Table Name"::"Service Contract" then begin
            if ServContract.Get(ServCommentLine."Table Subtype", ServCommentLine."No.") then
                exit(
                  StrSubstNo('%1 %2 %3 - %4 ', ServContract."Contract Type",
                    ServContract."Contract No.", ServContract.Description, ServCommentLine.Type));
        end;

        if ServCommentLine."Table Name" = ServCommentLine."Table Name"::"Service Item" then begin
            if ServItem.Get(ServCommentLine."No.") then
                exit(StrSubstNo('%1 %2 - %3 ', ServItem."No.", ServItem.Description, ServCommentLine.Type));
        end;

        if ServCommentLine."Table Name" = ServCommentLine."Table Name"::Loaner then
            if Loaner.Get(ServCommentLine."No.") then
                exit(StrSubstNo('%1 %2 - %3 ', Loaner."No.", Loaner.Description, ServCommentLine.Type));
    end;
}

