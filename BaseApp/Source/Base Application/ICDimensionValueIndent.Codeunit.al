codeunit 429 "IC Dimension Value-Indent"
{
    TableNo = "IC Dimension Value";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ICDimValueIndentQst, "Dimension Code"), true) then
            exit;
        ICDimVal.SetRange("Dimension Code", "Dimension Code");
        Indent();
    end;

    var
        ICDimVal: Record "IC Dimension Value";
        Window: Dialog;
        i: Integer;

        Text004: Label 'Indenting IC Dimension Values @1@@@@@@@@@@@@@@@@@@';
        Text005: Label 'End-Total %1 is missing a matching Begin-Total.';
        ICDimValueIndentQst: Label 'This function updates the indentation of all the IC dimension values for IC dimension %1. All IC dimension values between a Begin-Total and the matching End-Total are indented by one level. The Totaling field for each End-Total is also updated.\\Do you want to indent the IC dimension values?', Comment = '%1 - field value';

    local procedure Indent()
    var
        NoOfDimVals: Integer;
        Progress: Integer;
    begin
        Window.Open(Text004);

        NoOfDimVals := ICDimVal.Count();
        if NoOfDimVals = 0 then
            NoOfDimVals := 1;
        with ICDimVal do
            if FindSet() then
                repeat
                    Progress := Progress + 1;
                    Window.Update(1, 10000 * Progress div NoOfDimVals);
                    if "Dimension Value Type" = "Dimension Value Type"::"End-Total" then begin
                        if i < 1 then
                            Error(
                              Text005,
                              Code);
                        i := i - 1;
                    end;

                    Indentation := i;
                    Modify();

                    if "Dimension Value Type" = "Dimension Value Type"::"Begin-Total" then
                        i += 1;
                until Next() = 0;

        Window.Close();
    end;
}

