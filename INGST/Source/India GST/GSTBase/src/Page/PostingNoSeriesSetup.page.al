page 18006 "Posting No. Series Setup"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "Posting No. Series";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    ToolTip = 'Specifies the type of document that the entry belongs to.';
                }
                field("Select Condition"; SelectCondition)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Condition';
                    Editable = false;
                    ToolTip = 'Specifies the conditions required for this series to be used.';
                    trigger OnAssistEdit()
                    var
                        RequestPage: Codeunit "Dynamic Request";
                    begin
                        SelectCondition := '';
                        RequestPage.OpendynamicRequestPage(Rec);
                        SelectCondition := GetConditionAsDisplayText();
                    end;
                }
                field("Posting No. Series"; "Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting no. series for different documents type.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SelectCondition := '';
        if "Table Id" <> 0 then
            SelectCondition := GetConditionAsDisplayText();
    end;

    local procedure GetConditionAsDisplayText(): Text
    var
        Allobj: Record AllObj;
        RecordRef: RecordRef;
        IStream: InStream;
        COnditionText: Text;
        ExitMsg: Label 'Always';
    begin
        if Not Allobj.Get(Allobj."Object Type"::Table, "Table Id") then
            Exit(StrSubstNo(ObjectIDNotFoundErr, "Table Id"));
        RecordRef.OPEN("Table ID");
        CalcFields(Condition);
        if not Condition.HasValue() then
            exit(ExitMsg);

        Condition.CreateInStream(IStream);
        IStream.read(COnditionText);
        RecordRef.SetView(COnditionText);
        if RecordRef.GetFilters() <> '' then
            exit(RecordRef.GetFilters());
        RecordRef.Close();
    end;

    local procedure ConvertEventConditionsToFilters(var RecRef: RecordRef): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        if Condition.HasValue() then begin
            CalcFields(Condition);
            TempBlob.FromRecord(Rec, Rec.FieldNo(Condition));
            RequestPageParametersHelper.ConvertParametersToFilters(RecRef, TempBlob);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    Begin
        SelectCondition := '';
    end;

    var
        SelectCondition: Text;
        ObjectIDNotFoundErr: Label 'Error : Table ID %1 not found', Comment = '%1=Table Id';
}