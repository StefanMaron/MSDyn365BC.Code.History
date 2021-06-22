table 84 "Acc. Schedule Name"
{
    Caption = 'Acc. Schedule Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "Account Schedule Names";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(3; "Default Column Layout"; Code[10])
        {
            Caption = 'Default Column Layout';
            TableRelation = "Column Layout Name";
        }
        field(4; "Analysis View Name"; Code[10])
        {
            Caption = 'Analysis View Name';
            TableRelation = "Analysis View";

            trigger OnValidate()
            var
                AnalysisView: Record "Analysis View";
                xAnalysisView: Record "Analysis View";
                ConfirmManagement: Codeunit "Confirm Management";
                AskedUser: Boolean;
                ClearTotaling: Boolean;
                i: Integer;
            begin
                if xRec."Analysis View Name" <> "Analysis View Name" then begin
                    AnalysisViewGet(xAnalysisView, xRec."Analysis View Name");
                    AnalysisViewGet(AnalysisView, "Analysis View Name");

                    ClearTotaling := true;

                    for i := 1 to 4 do
                        if (GetDimCodeByNum(xAnalysisView, i) <> GetDimCodeByNum(AnalysisView, i)) and ClearTotaling then
                            if not DimTotalingLinesAreEmpty(i) then begin
                                if not AskedUser then begin
                                    ClearTotaling := ConfirmManagement.GetResponseOrDefault(ClearDimensionTotalingConfirmTxt, true);
                                    AskedUser := true;
                                end;

                                if ClearTotaling then
                                    ClearDimTotalingLines(i);
                            end;
                    if not ClearTotaling then
                        "Analysis View Name" := xRec."Analysis View Name";
                end;
            end;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        AccSchedLine.SetRange("Schedule Name", Name);
        AccSchedLine.DeleteAll();
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        ClearDimensionTotalingConfirmTxt: Label 'Changing Analysis View will clear differing dimension totaling columns of Account Schedule Lines. \Do you want to continue?';

    local procedure AnalysisViewGet(var AnalysisView: Record "Analysis View"; AnalysisViewName: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not AnalysisView.Get(AnalysisViewName) then
            if "Analysis View Name" = '' then begin
                GLSetup.Get();
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
    end;

    procedure DimTotalingLinesAreEmpty(DimNumber: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        AccSchedLine.Reset();
        AccSchedLine.SetRange("Schedule Name", Name);
        RecRef.GetTable(AccSchedLine);
        FieldRef := RecRef.Field(AccSchedLine.FieldNo("Dimension 1 Totaling") + DimNumber - 1);
        FieldRef.SetFilter('<>%1', '');
        RecRef := FieldRef.Record();
        exit(RecRef.IsEmpty());
    end;

    procedure ClearDimTotalingLines(DimNumber: Integer)
    var
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        AccSchedLine.Reset();
        AccSchedLine.SetRange("Schedule Name", Name);
        RecRef.GetTable(AccSchedLine);
        if RecRef.FindSet() then
            repeat
                FieldRef := RecRef.Field(AccSchedLine.FieldNo("Dimension 1 Totaling") + DimNumber - 1);
                FieldRef.Value := '';
                RecRef.Modify();
            until RecRef.Next() = 0;
    end;

    local procedure GetDimCodeByNum(AnalysisView: Record "Analysis View";   DimNumber: Integer) DimensionCode: Code[20]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(AnalysisView);
        FieldRef := RecRef.Field(AnalysisView.FieldNo("Dimension 1 Code") + DimNumber - 1);
        Evaluate(DimensionCode, Format(FieldRef.Value));
    end;

    procedure Print()
    var
        AccountSchedule: Report "Account Schedule";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrint(Rec, IsHandled);
        if IsHandled then
            exit;

        AccountSchedule.SetAccSchedName(Name);
        AccountSchedule.SetColumnLayoutName("Default Column Layout");
        AccountSchedule.Run;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(var AccScheduleName: Record "Acc. Schedule Name"; var IsHandled: Boolean)
    begin
    end;
}

