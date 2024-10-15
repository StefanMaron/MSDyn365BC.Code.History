xmlport 11765 "Unc. Payer List - Response"
{
    Caption = 'Unc. Payer List - Response';
    DefaultNamespace = 'http://adis.mfcr.cz/rozhraniCRPDPH/';
    Direction = Import;
    Encoding = UTF8;
    FormatEvaluate = Xml;
    Permissions = TableData "Uncertainty Payer Entry" = rimd;
    UseDefaultNamespace = true;
    UseRequestPage = false;

    schema
    {
        textelement(SeznamNespolehlivyPlatceResponse)
        {
            MaxOccurs = Once;
            MinOccurs = Zero;
            textelement(status)
            {
                MaxOccurs = Once;
                MinOccurs = Once;
                textattribute(bezVypisuUctu)
                {
                }
                textattribute(statusText)
                {
                    Occurrence = Optional;

                    trigger OnAfterAssignVariable()
                    begin
                        if statusText <> 'OK' then
                            Error(StatusErr, statusText);
                    end;
                }
                textattribute(statusCode)
                {
                    Occurrence = Optional;
                }
                textattribute(odpovedGenerovana)
                {
                    Occurrence = Optional;
                }
            }
            textelement(statusPlatceDPH)
            {
                MinOccurs = Zero;
                textattribute(cisloFu)
                {
                    Occurrence = Optional;
                }
                textattribute(datumZverejneniNespolehlivosti)
                {
                    Occurrence = Optional;
                }
                textattribute(nespolehlivyPlatce)
                {
                }
                textattribute(dic)
                {
                }

                trigger OnAfterAssignVariable()
                begin
                    InsertStatusToBuffer;
                    Clear(cisloFu);
                    Clear(datumZverejneniNespolehlivosti);
                    Clear(dic);
                    Clear(nespolehlivyPlatce);
                end;
            }
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

    trigger OnPostXmlPort()
    var
        EntryNo: Integer;
    begin
        // buffer process
        TempUncertaintyPayerEntry.Reset();
        if TempUncertaintyPayerEntry.FindSet then begin
            if not UncertaintyPayerEntry.FindLast then
                Clear(UncertaintyPayerEntry);
            EntryNo := UncertaintyPayerEntry."Entry No.";
            repeat
                UncertaintyPayerEntry.Reset();
                UncertaintyPayerEntry.SetCurrentKey("VAT Registration No.");
                UncertaintyPayerEntry.SetRange("VAT Registration No.", TempUncertaintyPayerEntry."VAT Registration No.");
                UncertaintyPayerEntry.SetRange("Entry Type", UncertaintyPayerEntry."Entry Type"::Payer);
                if not UncertaintyPayerEntry.FindLast then
                    Clear(UncertaintyPayerEntry);

                if (UncertaintyPayerEntry."Uncertainty Payer" <> TempUncertaintyPayerEntry."Uncertainty Payer") or
                   (UncertaintyPayerEntry."Tax Office Number" <> TempUncertaintyPayerEntry."Tax Office Number")
                then
                    UncertaintyPayerEntry."Entry No." := 0;  // new entry

                UncertaintyPayerEntry.Init();
                UncertaintyPayerEntry."Check Date" := TempUncertaintyPayerEntry."Check Date";
                UncertaintyPayerEntry."Public Date" := TempUncertaintyPayerEntry."Public Date";
                UncertaintyPayerEntry."Uncertainty Payer" := TempUncertaintyPayerEntry."Uncertainty Payer";
                UncertaintyPayerEntry."VAT Registration No." := TempUncertaintyPayerEntry."VAT Registration No.";
                UncertaintyPayerEntry."Tax Office Number" := TempUncertaintyPayerEntry."Tax Office Number";
                UncertaintyPayerEntry."Entry Type" := UncertaintyPayerEntry."Entry Type"::Payer;
                UncertaintyPayerEntry."Vendor No." := UncPayerMgt.GetVendFromVATRegNo(UncertaintyPayerEntry."VAT Registration No.");
                if UncertaintyPayerEntry."Entry No." > 0 then
                    UncertaintyPayerEntry.Modify
                else begin
                    EntryNo += 1;
                    UncertaintyPayerEntry."Entry No." := EntryNo;
                    UncertaintyPayerEntry.Insert();
                    TotalInsertedEntries += 1;
                end;
            until TempUncertaintyPayerEntry.Next = 0;
        end;
    end;

    var
        TempUncertaintyPayerEntry: Record "Uncertainty Payer Entry" temporary;
        UncertaintyPayerEntry: Record "Uncertainty Payer Entry";
        UncPayerMgt: Codeunit "Unc. Payer Mgt.";
        TotalInsertedEntries: Integer;
        UncPayerElementErr: Label 'Element "nespolehlivyPlatce" format error. Allow values are NE,ANO,NENALEZEN (%1).', Comment = '%1=ElementValue';
        StatusErr: Label 'Unhandled XML Error (%1).\Please check the xml file.', Comment = '%1=StatusText';

    local procedure InsertStatusToBuffer()
    begin
        if dic <> '' then begin
            TempUncertaintyPayerEntry.Init();
            TempUncertaintyPayerEntry."Entry No." += 1;
            TempUncertaintyPayerEntry."Check Date" := TextISOToDate(odpovedGenerovana);
            TempUncertaintyPayerEntry."Public Date" := TextISOToDate(datumZverejneniNespolehlivosti);
            TempUncertaintyPayerEntry."Uncertainty Payer" := UncPayerElementToOption(nespolehlivyPlatce);
            TempUncertaintyPayerEntry."Entry Type" := TempUncertaintyPayerEntry."Entry Type"::Payer;
            TempUncertaintyPayerEntry."VAT Registration No." := UncPayerMgt.GetLongVATRegNo(dic);
            TempUncertaintyPayerEntry."Tax Office Number" := cisloFu;
            TempUncertaintyPayerEntry.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetInsertEntryCount(): Integer
    begin
        exit(TotalInsertedEntries);
    end;

    local procedure TextISOToDate(Text: Text[30]): Date
    var
        YY: Integer;
        MM: Integer;
        DD: Integer;
    begin
        if Evaluate(DD, CopyStr(Text, 9, 2)) then
            if Evaluate(MM, CopyStr(Text, 6, 2)) then
                if Evaluate(YY, CopyStr(Text, 1, 4)) then
                    if (YY > 1754) and (MM <> 0) and (DD <> 0) then
                        exit(DMY2Date(DD, MM, YY));
    end;

    local procedure UncPayerElementToOption(UncPayerElementValue: Text[30]) ReturnValue: Integer
    begin
        case UpperCase(UncPayerElementValue) of
            'NE':
                ReturnValue := 1;
            'ANO':
                ReturnValue := 2;
            'NENALEZEN':
                ReturnValue := 3;
            else
                Error(UncPayerElementErr, UncPayerElementValue);
        end;
    end;
}

