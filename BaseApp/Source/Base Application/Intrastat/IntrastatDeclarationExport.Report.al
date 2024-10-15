report 31065 "Intrastat Declaration Export"
{
    Caption = 'Intrastat Declaration Export';
    ProcessingOnly = true;

    dataset
    {
        dataitem(IntrastatJnlBatch; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);

            trigger OnAfterGetRecord()
            begin
                TestField("Statistics Period");

                IntrastatJnlLine.Reset();
                IntrastatJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                IntrastatJnlLine.SetRange("Journal Batch Name", Name);
                if IntrastatJnlLine.FindSet then
                    repeat
                        case "Statement Type" of
                            "Statement Type"::Replacing,
                          "Statement Type"::Deleting:
                                ;
                            "Statement Type"::Null:
                                Error(Text11702);
                        end;
                        if IntrastatJnlLineType <> IntrastatJnlLineType::Null then
                            case IntrastatJnlLine.Type of
                                IntrastatJnlLine.Type::Receipt:
                                    if IntrastatJnlLineType <> IntrastatJnlLineType::Receive then
                                        IntrastatJnlLineType := IntrastatJnlLineType::"Send And Receive";
                                IntrastatJnlLine.Type::Shipment:
                                    if IntrastatJnlLineType <> IntrastatJnlLineType::Send then
                                        IntrastatJnlLineType := IntrastatJnlLineType::"Send And Receive";
                            end
                        else
                            case IntrastatJnlLine.Type of
                                IntrastatJnlLine.Type::Receipt:
                                    IntrastatJnlLineType := IntrastatJnlLineType::Receive;
                                IntrastatJnlLine.Type::Shipment:
                                    IntrastatJnlLineType := IntrastatJnlLineType::Send;
                            end;
                    until IntrastatJnlLine.Next = 0;

                ExportToCSV;
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                CompanyInfo.Get();
                StatReportingSetup.Get();
                Country.Get(CompanyInfo."Country/Region Code");
                case StatReportingSetup."Intrastat Rounding Type" of
                    StatReportingSetup."Intrastat Rounding Type"::Nearest:
                        Direction := '=';
                    StatReportingSetup."Intrastat Rounding Type"::Up:
                        Direction := '>';
                    StatReportingSetup."Intrastat Rounding Type"::Down:
                        Direction := '<';
                end;
                FieldSeparator := ';';
                FieldDelimeter := '"';

                SetRange("Journal Template Name", JnlTemplateName);
                SetRange(Name, JnlBatchName);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ContactPerson; ContactPerson)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact Person';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the contact person for intrastat declaration.';
                    }
                    field(ExportFormatField; ExportFormat)
                    {
                        Caption = 'Export Format';
                        ToolTip = 'Specifies the year for which to report Intrastat. This ensures that the report has the correct format for that year.';
                        ApplicationArea = BasicEU;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        USICu: Codeunit "Universal Single Inst. CU";
    begin
        USICu.GetIntrastatJnlParam(JnlTemplateName, JnlBatchName);
    end;

    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        StatReportingSetup: Record "Stat. Reporting Setup";
        Country: Record "Country/Region";
        TierMgt: Codeunit "File Management";
        FileName: Text;
        Text11700: Label 'Export of Intrastat Declaration';
        ContactPerson: Code[20];
        Text11702: Label 'There must not be any Intrastat Jnl. Lines if you choose Null Statement!';
        Text11703: Label 'CSV Files (*.csv)|*.csv|All Files (*.*)|*.*';
        JnlTemplateName: Code[10];
        JnlBatchName: Code[10];
        ExportFormat: Enum "Intrastat Export Format";
        IntrastatJnlLineType: Option Null,"Send And Receive",Receive,Send;
        ClientFileName: Text;
        Direction: Text[1];
        FieldSeparator: Text[10];
        FieldDelimeter: Text[10];
        StTxt: Label 'ST', Comment = 'ST';
        NnTxt: Label 'NN', Comment = 'NN';
        CzTxt: Label 'CZ', Comment = 'CZ';
        ToFileNameTxt: Label 'Default.csv';

    [Scope('OnPrem')]
    procedure ExportToCSV()
    var
        OutputFile: File;
        Month: Text[2];
        Year: Text[4];
        VATRegNo: Text[20];
        FieldValue: array[25] of Text[1000];
        ExportString: Text;
    begin
        ClientFileName := ToFileNameTxt;
        FileName := TierMgt.ServerTempFileName('.csv');

        OutputFile.TextMode(true);
        OutputFile.Create(FileName, TextEncoding::UTF8);

        Month := CopyStr(IntrastatJnlBatch."Statistics Period", 3);
        Year := '20' + CopyStr(IntrastatJnlBatch."Statistics Period", 1, 2);
        VATRegNo := CopyStr(CompanyInfo."VAT Registration No.", 1, 2);
        if VATRegNo = CzTxt then
            VATRegNo := CopyStr(CompanyInfo."VAT Registration No.", 3)
        else
            VATRegNo := CompanyInfo."VAT Registration No.";

        if IntrastatJnlLine.FindSet(true, false) then begin
            repeat
                with IntrastatJnlLine do begin
                    Clear(FieldValue);
                    if ExportFormat = ExportFormat::"2022" then begin
                        FieldValue[1] := Month;
                        FieldValue[2] := Year;
                        FieldValue[3] := VATRegNo;
                        FieldValue[4] := Format(Type + 1);
                        FieldValue[5] := GetIntrastatJnlLinePartnerVATID();
                        FieldValue[6] := CopyStr("Country/Region Code", 1, 2);
                        if Type = Type::Shipment then
                            FieldValue[7] := CopyStr(Area, 1, 2)
                        else
                            FieldValue[7] := '';
                        FieldValue[8] := CopyStr("Country/Region of Origin Code", 1, 2);
                        FieldValue[9] := CopyStr("Transaction Type", 1, 2);
                        FieldValue[10] := CopyStr("Transport Method", 1, 1);
                        FieldValue[11] := CopyStr(GetDeliveryGroupCode(), 1, 1);
                        FieldValue[12] := CopyStr(CreateDeclarationTypeCode(IntrastatJnlLine), 1, 2);
                        FieldValue[13] := "Tariff No.";
                        FieldValue[14] := CopyStr("Statistic Indication", 1, 2);
                        FieldValue[15] := "Item Description";
                        FieldValue[16] := GetTotalWeightStr();
                        FieldValue[17] := GetQuantityStr2022();
                        FieldValue[18] := Format(Round(Amount, 1, Direction), 0, 9);
                        FieldValue[19] := '';
                        FieldValue[20] := '';
                        FieldValue[21] := '';
                    end else begin
                        FieldValue[1] := Month;
                        FieldValue[2] := Year;
                        FieldValue[3] := VATRegNo;
                        FieldValue[4] := Format(Type + 1);
                        FieldValue[5] := CopyStr("Country/Region Code", 1, 2);
                        if Type = Type::Shipment then
                            FieldValue[6] := CopyStr(Area, 1, 2)
                        else
                            FieldValue[6] := '';
                        if (Type <> Type::Shipment) and ("Country/Region of Origin Code" <> '') then
                            FieldValue[7] := CopyStr("Country/Region of Origin Code", 1, 2);
                        FieldValue[8] := CopyStr("Transaction Type", 1, 2);
                        FieldValue[9] := CopyStr("Transport Method", 1, 1);
                        FieldValue[10] := CopyStr(GetDeliveryGroupCode(), 1, 1);
                        FieldValue[11] := CopyStr(CreateDeclarationTypeCode(IntrastatJnlLine), 1, 2);
                        FieldValue[12] := "Tariff No.";
                        FieldValue[13] := CopyStr("Statistic Indication", 1, 2);
                        FieldValue[14] := "Item Description";
                        FieldValue[15] := GetTotalWeightStr();
                        FieldValue[16] := GetQuantityStr();
                        FieldValue[17] := Format(Round(Amount, 1, Direction), 0, 9);
                        FieldValue[18] := '';
                        FieldValue[19] := '';
                        FieldValue[20] := '';
                    end;

                    ExportString := StringForExport(FieldValue, 20);
                    if ExportString <> '' then
                        OutputFile.Write(CopyStr(ExportString, 1, 1024));
                end;
            until IntrastatJnlLine.Next = 0;
        end;

        OutputFile.Close;

        Download(FileName, Text11700, '', Text11703, ClientFileName);
        Erase(FileName);
    end;

    local procedure GetIntrastatJnlLinePartnerVATID(): Text[25]
    begin
        if IntrastatJnlLine.Type <> IntrastatJnlLine.Type::Shipment then
            exit('');
        exit(CopyStr(IntrastatJnlLine."Partner VAT ID", 1, 25));
    end;

    local procedure GetQuantityStr2022(): Text[30]
    var
        TariffNumber: Record "Tariff Number";
        Quantity: Decimal;
    begin
        TariffNumber.Get(IntrastatJnlLine."Tariff No.");
        TariffNumber.CalcFields("Supplementary Units");
        if not TariffNumber."Supplementary Units" then
            exit(Format(0.0, 0, PrecisionFormat()));
        Quantity := IntrastatJnlLine."Supplem. UoM Quantity";
        if Quantity > 1 then
            Quantity := Round(Quantity, 1, Direction);
        exit(Format(Quantity, 0, PrecisionFormat()));
    end;

    local procedure PrecisionFormat(): Text
    begin
        exit('<Precision,3:3><Standard Format,9>');
    end;

    [Scope('OnPrem')]
    procedure CreateDeclarationTypeCode(var IntrastatJnlLine2: Record "Intrastat Jnl. Line"): Text[10]
    begin
        if IntrastatJnlBatch."Statement Type" <> IntrastatJnlBatch."Statement Type"::Null then begin
            if IntrastatJnlLine2."Specific Movement" <> '' then
                exit(IntrastatJnlLine2."Specific Movement");
            exit(StTxt);
        end;
        exit(NnTxt);
    end;

    [Scope('OnPrem')]
    procedure InitParameters(JnlTemplateName1: Code[10]; JnlBatchName1: Code[10])
    begin
        JnlTemplateName := JnlTemplateName1;
        JnlBatchName := JnlBatchName1;
    end;

    [Scope('OnPrem')]
    procedure StringForExport(FieldValue: array[25] of Text[1000]; NoOfFields: Integer) Result: Text
    var
        i: Integer;
    begin
        for i := 1 to NoOfFields do
            Result += FieldSeparator + FieldDelimeter + FieldValue[i] + FieldDelimeter;
        Result := CopyStr(Result, 2);
    end;
}

