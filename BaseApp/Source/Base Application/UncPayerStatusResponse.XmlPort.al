xmlport 11764 "Unc. Payer Status - Response"
{
    Caption = 'Unc. Payer Status - Response';
    DefaultNamespace = 'http://adis.mfcr.cz/rozhraniCRPDPH/';
    Direction = Import;
    Encoding = UTF8;
    FormatEvaluate = Xml;
    Permissions = TableData "Uncertainty Payer Entry" = rimd;
    UseDefaultNamespace = true;
    UseRequestPage = false;

    schema
    {
        textelement(StatusNespolehlivyPlatceResponse)
        {
            textelement(status)
            {
                MaxOccurs = Once;
                MinOccurs = Once;
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
                textattribute(nespolehlivyPlatce)
                {
                }
                textattribute(dic)
                {
                }
                textattribute(datumZverejneniNespolehlivosti)
                {
                    Occurrence = Optional;
                }
                textelement(zverejneneUcty)
                {
                    MinOccurs = Zero;
                    textelement(ucet)
                    {
                        MinOccurs = Zero;
                        textattribute(datumZverejneniUkonceni)
                        {
                            Occurrence = Optional;
                        }
                        textattribute(datumZverejneni)
                        {
                            Occurrence = Required;
                        }
                        textelement(standardniUcet)
                        {
                            MinOccurs = Zero;
                            textattribute(kodBanky)
                            {
                                Occurrence = Optional;
                            }
                            textattribute(cislostandardba)
                            {
                                Occurrence = Optional;
                                XmlName = 'cislo';
                            }
                            textattribute(predcisli)
                            {
                                Occurrence = Optional;
                            }

                            trigger OnAfterAssignVariable()
                            begin
                                InsertBankAccountToBuffer;
                                Clear(cisloStandardBA);
                                Clear(kodBanky);
                                Clear(predcisli);
                                Clear(cisloNoStandardBA);
                            end;
                        }
                        textelement(nestandardniUcet)
                        {
                            MinOccurs = Zero;
                            textattribute(cislonostandardba)
                            {
                                Occurrence = Optional;
                                XmlName = 'cislo';
                            }

                            trigger OnAfterAssignVariable()
                            begin
                                InsertBankAccountToBuffer;
                                Clear(cisloNoStandardBA);
                            end;
                        }

                        trigger OnAfterAssignVariable()
                        begin
                            Clear(datumZverejneni);
                            Clear(datumZverejneniUkonceni);
                        end;
                    }
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
        TempUncertaintyPayerEntry.Reset;
        if TempUncertaintyPayerEntry.FindSet then begin
            if not UncertaintyPayerEntry.FindLast then
                Clear(UncertaintyPayerEntry);
            EntryNo := UncertaintyPayerEntry."Entry No.";
            repeat
                UncertaintyPayerEntry.Reset;
                UncertaintyPayerEntry.SetCurrentKey("VAT Registration No.");
                UncertaintyPayerEntry.SetRange("VAT Registration No.", TempUncertaintyPayerEntry."VAT Registration No.");
                UncertaintyPayerEntry.SetRange("Entry Type", UncertaintyPayerEntry."Entry Type"::Payer);
                if not UncertaintyPayerEntry.FindLast then
                    Clear(UncertaintyPayerEntry);

                if (UncertaintyPayerEntry."Uncertainty Payer" <> TempUncertaintyPayerEntry."Uncertainty Payer") or
                   (UncertaintyPayerEntry."Tax Office Number" <> TempUncertaintyPayerEntry."Tax Office Number")
                then
                    UncertaintyPayerEntry."Entry No." := 0;  // new entry

                UncertaintyPayerEntry.Init;
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
                    UncertaintyPayerEntry.Insert;
                    TotalInsertedEntries += 1;
                end;

                // Bank account
                TempUncertaintyPayerEntry2.SetRange("VAT Registration No.", TempUncertaintyPayerEntry."VAT Registration No.");
                if TempUncertaintyPayerEntry2.FindSet then
                    repeat
                        UncertaintyPayerEntry.Reset;
                        UncertaintyPayerEntry.SetCurrentKey("VAT Registration No.");
                        UncertaintyPayerEntry.SetRange("VAT Registration No.", TempUncertaintyPayerEntry2."VAT Registration No.");
                        UncertaintyPayerEntry.SetRange("Entry Type", UncertaintyPayerEntry."Entry Type"::"Bank Account");
                        UncertaintyPayerEntry.SetRange("Full Bank Account No.", TempUncertaintyPayerEntry2."Full Bank Account No.");
                        if not UncertaintyPayerEntry.FindLast then
                            Clear(UncertaintyPayerEntry);

                        if UncertaintyPayerEntry."Bank Account No. Type" <> TempUncertaintyPayerEntry2."Bank Account No. Type" then
                            UncertaintyPayerEntry."Entry No." := 0;  // new entry

                        UncertaintyPayerEntry.Init;
                        UncertaintyPayerEntry."Check Date" := TempUncertaintyPayerEntry2."Check Date";
                        UncertaintyPayerEntry."Public Date" := TempUncertaintyPayerEntry2."Public Date";
                        UncertaintyPayerEntry."End Public Date" := TempUncertaintyPayerEntry2."End Public Date";
                        UncertaintyPayerEntry."VAT Registration No." := TempUncertaintyPayerEntry2."VAT Registration No.";
                        UncertaintyPayerEntry."Full Bank Account No." := TempUncertaintyPayerEntry2."Full Bank Account No.";
                        UncertaintyPayerEntry."Bank Account No. Type" := TempUncertaintyPayerEntry2."Bank Account No. Type";
                        UncertaintyPayerEntry."Entry Type" := UncertaintyPayerEntry."Entry Type"::"Bank Account";
                        UncertaintyPayerEntry."Vendor No." := UncPayerMgt.GetVendFromVATRegNo(UncertaintyPayerEntry."VAT Registration No.");
                        if UncertaintyPayerEntry."Entry No." > 0 then
                            UncertaintyPayerEntry.Modify
                        else begin
                            EntryNo += 1;
                            UncertaintyPayerEntry."Entry No." := EntryNo;
                            UncertaintyPayerEntry.Insert;
                            TotalInsertedEntries += 1;
                        end;
                    until TempUncertaintyPayerEntry2.Next = 0;

                if not TempDimBuf.Get(0, 0, TempUncertaintyPayerEntry."VAT Registration No.") then begin
                    TempDimBuf.Init;
                    TempDimBuf."Table ID" := 0;
                    TempDimBuf."Entry No." := 0;
                    TempDimBuf."Dimension Code" := TempUncertaintyPayerEntry."VAT Registration No.";
                    TempDimBuf.Insert;
                end;
            until TempUncertaintyPayerEntry.Next = 0;

            // end public bank account update - this records not in actual xml file!
            if TempDimBuf.FindSet then
                repeat
                    UncertaintyPayerEntry.Reset;
                    UncertaintyPayerEntry.SetCurrentKey("VAT Registration No.");
                    UncertaintyPayerEntry.SetRange("VAT Registration No.", TempDimBuf."Dimension Code");
                    UncertaintyPayerEntry.SetRange("Entry Type", UncertaintyPayerEntry."Entry Type"::"Bank Account");
                    UncertaintyPayerEntry.SetFilter("Check Date", '<>%1', TextISOToDate(odpovedGenerovana));
                    if UncertaintyPayerEntry.FindSet then
                        repeat
                            if UncertaintyPayerEntry."End Public Date" = 0D then begin
                                UncertaintyPayerEntry."End Public Date" := TextISOToDate(odpovedGenerovana) - 1;
                                UncertaintyPayerEntry.Modify;
                            end;
                        until UncertaintyPayerEntry.Next = 0;
                until TempDimBuf.Next = 0;
        end;
    end;

    var
        TempUncertaintyPayerEntry: Record "Uncertainty Payer Entry" temporary;
        TempUncertaintyPayerEntry2: Record "Uncertainty Payer Entry" temporary;
        UncertaintyPayerEntry: Record "Uncertainty Payer Entry";
        TempDimBuf: Record "Dimension Buffer" temporary;
        UncPayerMgt: Codeunit "Unc. Payer Mgt.";
        TotalInsertedEntries: Integer;
        UncPayerElementErr: Label 'Element "nespolehlivyPlatce" format error. Allow values are NE,ANO,NENALEZEN (%1).', Comment = '%1=ElementValue';
        StatusErr: Label 'Unhandled XML Error (%1).\ Please check the xml file.', Comment = '%1=StatusText';

    local procedure InsertStatusToBuffer()
    begin
        if dic <> '' then begin
            TempUncertaintyPayerEntry.Init;
            TempUncertaintyPayerEntry."Entry No." += 1;
            TempUncertaintyPayerEntry."Check Date" := TextISOToDate(odpovedGenerovana);
            TempUncertaintyPayerEntry."Public Date" := TextISOToDate(datumZverejneniNespolehlivosti);
            TempUncertaintyPayerEntry."Uncertainty Payer" := UncPayerElementToOption(nespolehlivyPlatce);
            TempUncertaintyPayerEntry."Entry Type" := TempUncertaintyPayerEntry."Entry Type"::Payer;
            TempUncertaintyPayerEntry."VAT Registration No." := UncPayerMgt.GetLongVATRegNo(dic);
            TempUncertaintyPayerEntry."Tax Office Number" := cisloFu;
            TempUncertaintyPayerEntry.Insert;
        end;
    end;

    local procedure InsertBankAccountToBuffer()
    begin
        if (dic <> '') and ((cisloStandardBA <> '') or (cisloNoStandardBA <> '')) then begin
            TempUncertaintyPayerEntry2.Init;
            TempUncertaintyPayerEntry2."Entry No." += 1;
            TempUncertaintyPayerEntry2."Check Date" := TextISOToDate(odpovedGenerovana);
            TempUncertaintyPayerEntry2."Public Date" := TextISOToDate(datumZverejneni);
            TempUncertaintyPayerEntry2."End Public Date" := TextISOToDate(datumZverejneniUkonceni);
            TempUncertaintyPayerEntry2."Entry Type" := TempUncertaintyPayerEntry."Entry Type"::"Bank Account";
            TempUncertaintyPayerEntry2."VAT Registration No." := UncPayerMgt.GetLongVATRegNo(dic);
            if cisloStandardBA <> '' then begin
                if predcisli <> '' then
                    TempUncertaintyPayerEntry2."Full Bank Account No." := predcisli + '-';
                TempUncertaintyPayerEntry2."Full Bank Account No." := TempUncertaintyPayerEntry2."Full Bank Account No." +
                  cisloStandardBA + '/' + kodBanky;
            end;
            if cisloNoStandardBA <> '' then begin
                TempUncertaintyPayerEntry2."Full Bank Account No." := cisloNoStandardBA;
                TempUncertaintyPayerEntry2."Bank Account No. Type" := TempUncertaintyPayerEntry2."Bank Account No. Type"::"No standard";
            end;
            TempUncertaintyPayerEntry2.Insert;
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

