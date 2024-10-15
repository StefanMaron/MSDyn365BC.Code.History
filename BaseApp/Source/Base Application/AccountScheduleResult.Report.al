report 31082 "Account Schedule Result"
{
    DefaultLayout = RDLC;
    RDLCLayout = './AccountScheduleResult.rdlc';
    Caption = 'Account Schedule Result';

    dataset
    {
        dataitem("Acc. Schedule Result Header"; "Acc. Schedule Result Header")
        {
            column(Acc__Schedule_Result_Header_Result_Code; "Result Code")
            {
            }
            dataitem("Acc. Schedule Result Line"; "Acc. Schedule Result Line")
            {
                DataItemLink = "Result Code" = FIELD("Result Code");
                DataItemTableView = SORTING("Result Code", "Line No.");
                column(AccScheduleName_Description; AccScheduleName.Description)
                {
                }
                column(Acc__Schedule_Result_Header___Date_Filter_; "Acc. Schedule Result Header"."Date Filter")
                {
                }
                column(Acc__Schedule_Result_Header___Column_Layout_Name_; "Acc. Schedule Result Header"."Column Layout Name")
                {
                }
                column(AccScheduleName_Name; AccScheduleName.Name)
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(Acc__Schedule_Result_Header__Description; "Acc. Schedule Result Header".Description)
                {
                }
                column(Header_1_; Header[1])
                {
                }
                column(Header_2_; Header[2])
                {
                }
                column(Header_3_; Header[3])
                {
                }
                column(Header_4_; Header[4])
                {
                }
                column(Header_5_; Header[5])
                {
                }
                column(ColumnValuesAsText_5_; ColumnValuesAsText[5])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_4_; ColumnValuesAsText[4])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_3_; ColumnValuesAsText[3])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2_; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_1_; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Result_Line__Row_No__; "Row No.")
                {
                }
                column(Acc__Schedule_Result_Line_Description; Description)
                {
                }
                column(ColumnValuesAsText_5__Control1470012; ColumnValuesAsText[5])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_4__Control1470021; ColumnValuesAsText[4])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_3__Control1470027; ColumnValuesAsText[3])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1470029; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_1__Control1470033; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Result_Line__Row_No___Control1470034; "Row No.")
                {
                }
                column(Acc__Schedule_Result_Line_Description_Control1470035; Description)
                {
                }
                column(ColumnValuesAsText_5__Control1470036; ColumnValuesAsText[5])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_4__Control1470037; ColumnValuesAsText[4])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_3__Control1470038; ColumnValuesAsText[3])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1470039; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_1__Control1470040; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Result_Line__Row_No___Control1470041; "Row No.")
                {
                }
                column(Acc__Schedule_Result_Line_Description_Control1470042; Description)
                {
                }
                column(ColumnValuesAsText_5__Control1470043; ColumnValuesAsText[5])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_4__Control1470044; ColumnValuesAsText[4])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_3__Control1470045; ColumnValuesAsText[3])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1470046; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_1__Control1470047; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Result_Line__Row_No___Control1470048; "Row No.")
                {
                }
                column(Acc__Schedule_Result_Line_Description_Control1470049; Description)
                {
                }
                column(Acc__Schedule_Result_Header___Date_Filter_Caption; Acc__Schedule_Result_Header___Date_Filter_CaptionLbl)
                {
                }
                column(Column_LayoutCaption; Column_LayoutCaptionLbl)
                {
                }
                column(AccScheduleName_NameCaption; AccScheduleName_NameCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Account_ScheduleCaption; Account_ScheduleCaptionLbl)
                {
                }
                column(Result_DescriptionCaption; Result_DescriptionCaptionLbl)
                {
                }
                column(Acc__Schedule_Result_Line__Row_No__Caption; FieldCaption("Row No."))
                {
                }
                column(Acc__Schedule_Result_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Acc__Schedule_Result_Line_Result_Code; "Result Code")
                {
                }
                column(Acc__Schedule_Result_Line_Line_No_; "Line No.")
                {
                }
                column(Hide_Line; Show = Show::No)
                {
                }
                column(Bold_Line; Bold)
                {
                }
                column(Italic_Line; Italic)
                {
                }
                column(UnderLine_Line; Underline)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(ColumnValuesAsText);
                    i := 0;

                    AccScheduleResultColumn.SetRange("Result Code", "Result Code");
                    if AccScheduleResultColumn.FindSet then
                        repeat
                            i := i + 1;
                            if AccScheduleResultValue.Get(
                                 "Acc. Schedule Result Header"."Result Code",
                                 "Line No.",
                                 AccScheduleResultColumn."Line No.")
                            then
                                if AccScheduleResultValue.Value <> 0 then
                                    ColumnValuesAsText[i] := Format(AccScheduleResultValue.Value);
                        until AccScheduleResultColumn.Next() = 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                AccScheduleName.Get("Acc. Schedule Name");
                Clear(Header);
                i := 0;

                AccScheduleResultColumn.SetRange("Result Code", "Result Code");
                if AccScheduleResultColumn.FindSet then
                    repeat
                        i := i + 1;
                        Header[i] := AccScheduleResultColumn."Column Header";
                    until AccScheduleResultColumn.Next() = 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleResultColumn: Record "Acc. Schedule Result Column";
        AccScheduleResultValue: Record "Acc. Schedule Result Value";
        ColumnValuesAsText: array[5] of Text[30];
        Header: array[5] of Text[50];
        i: Integer;
        Acc__Schedule_Result_Header___Date_Filter_CaptionLbl: Label 'Period';
        Column_LayoutCaptionLbl: Label 'Column Layout';
        AccScheduleName_NameCaptionLbl: Label 'Account Schedule';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Account_ScheduleCaptionLbl: Label 'Account Schedule';
        Result_DescriptionCaptionLbl: Label 'Result Description';
}

