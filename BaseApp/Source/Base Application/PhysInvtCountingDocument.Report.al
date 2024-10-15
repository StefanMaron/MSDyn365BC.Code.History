report 31074 "Phys. Invt. Counting Document"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PhysInvtCountingDocument.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Phys. Invt. Counting Document';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PhysInvLedgEntry; "Phys. Inventory Ledger Entry")
        {
            RequestFilterFields = "Document No.", "Posting Date", "Location Code", "Item No.", "Variant Code";
            column(CompanyInfo_Name; CompanyInfo.Name)
            {
            }
            column(CompanyInfo_Address__________CompanyInfo_City__________CompanyInfo__Post_Code_; CompanyInfo.Address + ', ' + CompanyInfo.City + ', ' + CompanyInfo."Post Code")
            {
            }
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(FORMAT_WORKDATE_0_4_; Format(WorkDate, 0, 4))
            {
            }
            column(HeaderText2_Date; HeaderText2 + Format(DocumentDate))
            {
            }
            column(HeaderText1_DocumentNo; HeaderText1 + DocumentNo)
            {
            }
            column(USERID; UserId)
            {
            }
            column(CompanyInfo__Registration_No__; CompanyInfo."Registration No.")
            {
            }
            column(CompanyInfo__Tax_Registration_No__; CompanyInfo."Tax Registration No.")
            {
            }
            column(Reason; Reason)
            {
            }
            column(Members; Members)
            {
            }
            column(Location_Name; Location.Name)
            {
            }
            column(GETFILTERS; GetFilters)
            {
            }
            column(CompanyInfo_Name_Control1470044; CompanyInfo.Name)
            {
            }
            column(HeaderText1___DocumentNo_Control1470047; HeaderText1 + DocumentNo)
            {
            }
            column(PhysInvLedgEntry__Item_No__; "Item No.")
            {
            }
            column(DescriptionText; DescriptionText)
            {
            }
            column(PhysInvLedgEntry__Unit_of_Measure_Code_; "Unit of Measure Code")
            {
            }
            column(PhysInvLedgEntry__Qty___Calculated__; "Qty. (Calculated)")
            {
            }
            column(PhysInvLedgEntry__Qty___Phys__Inventory__; "Qty. (Phys. Inventory)")
            {
            }
            column(Qty___Phys__Inventory______Qty___Calculated__; "Qty. (Phys. Inventory)" - "Qty. (Calculated)")
            {
                DecimalPlaces = 0 : 5;
            }
            column(PhysInvLedgEntry__Unit_Cost_; "Unit Cost")
            {
            }
            column(ChangeCost; ChangeCost)
            {
            }
            column(Qty___Calculated______Unit_Cost____ChangeCost; "Qty. (Calculated)" * "Unit Cost" + ChangeCost)
            {
            }
            column(PageTotals_5_; PageTotals[5])
            {
            }
            column(PageTotals_4_; PageTotals[4])
            {
            }
            column(PageTotals_3_; PageTotals[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PageTotals_2_; PageTotals[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PageTotals_1_; PageTotals[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Totals_1_; Totals[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Totals_2_; Totals[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Totals_3_; Totals[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Totals_4_; Totals[4])
            {
            }
            column(Totals_5_; Totals[5])
            {
            }
            column(ConfirmationText; StrSubstNo(Text26503, Format(DocumentDate)))
            {
            }
            column(Member_1_; Member[1])
            {
            }
            column(Member_2_; Member[2])
            {
            }
            column(Member_3_; Member[3])
            {
            }
            column(Member_4_; Member[4])
            {
            }
            column(Company_Caption; Company_CaptionLbl)
            {
            }
            column(Address_Caption; Address_CaptionLbl)
            {
            }
            column(VAT_Reg__No__Caption; VAT_Reg__No__CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Reg__No__Caption; Reg__No__CaptionLbl)
            {
            }
            column(Tax_Reg__No__Caption; Tax_Reg__No__CaptionLbl)
            {
            }
            column(Reason_Caption; Reason_CaptionLbl)
            {
            }
            column(Commission_in_staff_of_Caption; Commission_in_staff_of_CaptionLbl)
            {
            }
            column(draw_up_this_documentCaption; draw_up_this_documentCaptionLbl)
            {
            }
            column(Department_Caption; Department_CaptionLbl)
            {
            }
            column(Location_Caption; Location_CaptionLbl)
            {
            }
            column(Total_Item_AmountCaption; Total_Item_AmountCaptionLbl)
            {
            }
            column(PhysInvLedgEntry__Unit_Cost_Caption; FieldCaption("Unit Cost"))
            {
            }
            column(Changes_CostCaption; Changes_CostCaptionLbl)
            {
            }
            column(Qty__ChangesCaption; Qty__ChangesCaptionLbl)
            {
            }
            column(Qty___Invent__Caption; Qty___Invent__CaptionLbl)
            {
            }
            column(Qty___Calc__Caption; Qty___Calc__CaptionLbl)
            {
            }
            column(Unit_of_MeasureCaption; Unit_of_MeasureCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(PhysInvLedgEntry__Item_No__Caption; FieldCaption("Item No."))
            {
            }
            column(Total_Item_AmountCaption_Control1470031; Total_Item_AmountCaption_Control1470031Lbl)
            {
            }
            column(Unit_CostCaption; Unit_CostCaptionLbl)
            {
            }
            column(Changes_CostCaption_Control1470033; Changes_CostCaption_Control1470033Lbl)
            {
            }
            column(Qty__ChangesCaption_Control1470034; Qty__ChangesCaption_Control1470034Lbl)
            {
            }
            column(Qty___Invent__Caption_Control1470035; Qty___Invent__Caption_Control1470035Lbl)
            {
            }
            column(Qty___Calc__Caption_Control1470036; Qty___Calc__Caption_Control1470036Lbl)
            {
            }
            column(Unit_of_MeasureCaption_Control1470037; Unit_of_MeasureCaption_Control1470037Lbl)
            {
            }
            column(DescriptionCaption_Control1470038; DescriptionCaption_Control1470038Lbl)
            {
            }
            column(Item_No_Caption; Item_No_CaptionLbl)
            {
            }
            column(Company_Caption_Control1470043; Company_Caption_Control1470043Lbl)
            {
            }
            column(CurrReport_PAGENO___1Caption; CurrReport_PAGENO___1CaptionLbl)
            {
            }
            column(Total_for_page_statement__Quantity__Amount__Caption; Total_for_page_statement__Quantity__Amount__CaptionLbl)
            {
            }
            column(CurrReport_PAGENO___1_Control1470058Caption; CurrReport_PAGENO___1_Control1470058CaptionLbl)
            {
            }
            column(Total_changes__Quantity__Amount__Caption; Total_changes__Quantity__Amount__CaptionLbl)
            {
            }
            column(Total_statement__Quantity__Amount__Caption; Total_statement__Quantity__Amount__CaptionLbl)
            {
            }
            column(Confirmed_by_manager_Caption; Confirmed_by_manager_CaptionLbl)
            {
            }
            column(name_Caption; name_CaptionLbl)
            {
            }
            column(signature_Caption; signature_CaptionLbl)
            {
            }
            column(signature_Caption_Control1470082; signature_Caption_Control1470082Lbl)
            {
            }
            column(PhysInvLedgEntry_Entry_No_; "Entry No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Description = '' then
                    if Item.Get("Item No.") then
                        DescriptionText := Item.Description;
                if Location.Code <> "Location Code" then
                    if not Location.Get("Location Code") then
                        Clear(Location);

                ItemLedgEntry.Reset();
                ItemLedgEntry.SetCurrentKey("Item No.");
                ItemLedgEntry.SetRange("Document No.", "Document No.");
                ItemLedgEntry.SetRange("Posting Date", "Posting Date");
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange("Variant Code", "Variant Code");
                ItemLedgEntry.SetRange("Location Code", "Location Code");
                ItemLedgEntry.SetRange("Entry Type", "Entry Type");
                case ItemLedgEntry.Count of
                    0:
                        ChangeCost := 0;
                    1:
                        begin
                            ItemLedgEntry.FindFirst;
                            ItemLedgEntry.CalcFields("Cost Amount (Actual)");
                            ChangeCost := ItemLedgEntry."Cost Amount (Actual)";
                        end;
                    else begin
                            ItemLedgEntry.FindSet;
                            repeat
                                ItemLedgEntry.CalcFields("Cost Amount (Actual)");
                                ChangeCost := ChangeCost + ItemLedgEntry."Cost Amount (Actual)";
                                ChangeQty := ChangeQty + ItemLedgEntry.Quantity;
                            until ItemLedgEntry.Next = 0;
                            ChangeCost := Round(ChangeCost / ChangeQty * ("Qty. (Phys. Inventory)" - "Qty. (Calculated)"), 0.01);
                        end;
                end;

                Totals[1] := Totals[1] + "Qty. (Calculated)";
                Totals[2] := Totals[2] + "Qty. (Phys. Inventory)";
                Totals[3] := Totals[3] + ("Qty. (Phys. Inventory)" - "Qty. (Calculated)");
                Totals[4] := Totals[4] + ChangeCost;
                Totals[5] := Totals[5] + ("Qty. (Calculated)" * "Unit Cost" + ChangeCost);

                TempTotals[1] := TempTotals[1] + "Qty. (Calculated)";
                TempTotals[2] := TempTotals[2] + "Qty. (Phys. Inventory)";
                TempTotals[3] := TempTotals[3] + ("Qty. (Phys. Inventory)" - "Qty. (Calculated)");
                TempTotals[4] := TempTotals[4] + ChangeCost;
                TempTotals[5] := TempTotals[5] + ("Qty. (Calculated)" * "Unit Cost" + ChangeCost);
            end;

            trigger OnPreDataItem()
            begin
                Clear(Totals);
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
                    field(Reason; Reason)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Reason';
                        ToolTip = 'Specifies the document reason.';
                    }
                    field("Member[1]"; Member[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '1. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CompanyOfficials.Reset();
                            if PAGE.RunModal(PAGE::"Company Officials", CompanyOfficials) = ACTION::LookupOK then
                                Member[1] := CompanyOfficials.FullName;
                        end;
                    }
                    field("Member[2]"; Member[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '2. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CompanyOfficials.Reset();
                            if PAGE.RunModal(PAGE::"Company Officials", CompanyOfficials) = ACTION::LookupOK then
                                Member[2] := CompanyOfficials.FullName;
                        end;
                    }
                    field("Member[3]"; Member[3])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '3. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CompanyOfficials.Reset();
                            if PAGE.RunModal(PAGE::"Company Officials", CompanyOfficials) = ACTION::LookupOK then
                                Member[3] := CompanyOfficials.FullName;
                        end;
                    }
                    field("Member[4]"; Member[4])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '4. Persona';
                        ToolTip = 'Specifies an employee name from the Company Officials table. Each persona will print on the report with a corresponding signature line for authorization.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            CompanyOfficials.Reset();
                            if PAGE.RunModal(PAGE::"Company Officials", CompanyOfficials) = ACTION::LookupOK then
                                Member[4] := CompanyOfficials.FullName;
                        end;
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

    trigger OnPreReport()
    begin
        CompanyInfo.Get();

        if PhysInvLedgEntry.GetRangeMin("Document No.") <> PhysInvLedgEntry.GetRangeMax("Document No.") then
            Error(Text26501, PhysInvLedgEntry.FieldCaption("Document No."));
        DocumentNo := PhysInvLedgEntry.GetRangeMax("Document No.");

        if PhysInvLedgEntry.GetRangeMin("Posting Date") <> PhysInvLedgEntry.GetRangeMax("Posting Date") then
            Error(Text26501, PhysInvLedgEntry.FieldCaption("Posting Date"));
        DocumentDate := PhysInvLedgEntry.GetRangeMax("Posting Date");

        if Member[1] <> '' then
            Members := Members + Member[1];

        if Member[2] <> '' then begin
            if Members <> '' then
                Members := Members + ',' + Member[2]
            else
                Members := Member[2];
        end;

        if Member[3] <> '' then begin
            if Members <> '' then
                Members := Members + ',' + Member[3]
            else
                Members := Member[3];
        end;

        if Member[4] <> '' then begin
            if Members <> '' then
                Members := Members + ',' + Member[4]
            else
                Members := Member[4];
        end;
    end;

    var
        CompanyOfficials: Record "Company Officials";
        CompanyInfo: Record "Company Information";
        Item: Record Item;
        Location: Record Location;
        ItemLedgEntry: Record "Item Ledger Entry";
        Member: array[4] of Text[100];
        Reason: Text[250];
        DocumentNo: Code[20];
        ChangeCost: Decimal;
        ChangeQty: Decimal;
        DescriptionText: Text[100];
        Totals: array[5] of Decimal;
        TempTotals: array[5] of Decimal;
        PageTotals: array[5] of Decimal;
        Members: Text[360];
        DocumentDate: Date;
        Text26501: Label 'Please select only one %1.';
        HeaderText1: Label 'INVENTORY COUNTING DOCUMENT No.';
        HeaderText2: Label 'for situation on:';
        Text26503: Label 'We, signed this document, confirm Inventory counting results at %1';
        Company_CaptionLbl: Label 'Company:';
        Address_CaptionLbl: Label 'Address:';
        VAT_Reg__No__CaptionLbl: Label 'VAT Reg. No.:';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Reg__No__CaptionLbl: Label 'Reg. No.:';
        Tax_Reg__No__CaptionLbl: Label 'Tax Reg. No.:';
        Reason_CaptionLbl: Label 'Reason:';
        Commission_in_staff_of_CaptionLbl: Label 'Commission in staff of:';
        draw_up_this_documentCaptionLbl: Label 'draw up this document';
        Department_CaptionLbl: Label 'Department:';
        Location_CaptionLbl: Label 'Location:';
        Total_Item_AmountCaptionLbl: Label 'Total Item Amount';
        Changes_CostCaptionLbl: Label 'Changes Cost';
        Qty__ChangesCaptionLbl: Label 'Qty. Changes';
        Qty___Invent__CaptionLbl: Label 'Qty. (Invent.)';
        Qty___Calc__CaptionLbl: Label 'Qty. (Calc.)';
        Unit_of_MeasureCaptionLbl: Label 'Unit of Measure';
        DescriptionCaptionLbl: Label 'Description';
        Total_Item_AmountCaption_Control1470031Lbl: Label 'Total Item Amount';
        Unit_CostCaptionLbl: Label 'Unit Cost';
        Changes_CostCaption_Control1470033Lbl: Label 'Changes Cost';
        Qty__ChangesCaption_Control1470034Lbl: Label 'Qty. Changes';
        Qty___Invent__Caption_Control1470035Lbl: Label 'Qty. (Invent.)';
        Qty___Calc__Caption_Control1470036Lbl: Label 'Qty. (Calc.)';
        Unit_of_MeasureCaption_Control1470037Lbl: Label 'Unit of Measure';
        DescriptionCaption_Control1470038Lbl: Label 'Description';
        Item_No_CaptionLbl: Label 'Item No.';
        Company_Caption_Control1470043Lbl: Label 'Company:';
        CurrReport_PAGENO___1CaptionLbl: Label 'Continued from page';
        Total_for_page_statement__Quantity__Amount__CaptionLbl: Label 'Total for page statement (Quantity, Amount):';
        CurrReport_PAGENO___1_Control1470058CaptionLbl: Label 'Continued to page';
        Total_changes__Quantity__Amount__CaptionLbl: Label 'Total changes (Quantity, Amount):';
        Total_statement__Quantity__Amount__CaptionLbl: Label 'Total statement (Quantity, Amount):';
        Confirmed_by_manager_CaptionLbl: Label 'Confirmed by manager:';
        name_CaptionLbl: Label '(name)';
        signature_CaptionLbl: Label '(signature)';
        signature_Caption_Control1470082Lbl: Label '(signature)';
}

