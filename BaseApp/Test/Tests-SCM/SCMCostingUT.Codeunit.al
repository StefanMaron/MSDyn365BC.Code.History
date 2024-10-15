codeunit 137811 "SCM - Costing UT"
{
    Permissions = TableData "Value Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Stockkeeping Unit] [SCM]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF327751()
    begin
        // test negative amount - roots of bug fixed
        UpdateUnitCostOfSKU(-0.00024);

        // test zero amount - this doesn't exist after adjustment but we need to be sure the field Unit Cost is not changed
        UpdateUnitCostOfSKU(0);

        // test positive amount
        UpdateUnitCostOfSKU(0.00024);
    end;

    local procedure UpdateUnitCostOfSKU(NewUnitCost: Decimal)
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ValueEntry: Record "Value Entry";
        InventorySetup: Record "Inventory Setup";
        ItemCostManagement: Codeunit ItemCostManagement;
        OldAvgCostCalcType: Enum "Average Cost Calculation Type";
    begin
        // Initialize of needed records
        SetupItem(Item);
        SetupSKU(SKU, Item);
        SetupValueEntry(ValueEntry, SKU, NewUnitCost);

        InventorySetup.Get();
        OldAvgCostCalcType := InventorySetup."Average Cost Calc. Type";
        InventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant";
        InventorySetup.Modify();

        // Execution of test
        // test of function
        ItemCostManagement.SetProperties(true, 1);
        ItemCostManagement.UpdateUnitCostSKU(Item, SKU, 0, NewUnitCost, false, 0);

        // Verification of results
        VerifyUnitCostOfSKU(SKU."Unit Cost", Item."Unit Cost", NewUnitCost);

        // restore original value of Inventory Setup
        if OldAvgCostCalcType <> InventorySetup."Average Cost Calc. Type" then begin
            InventorySetup."Average Cost Calc. Type" := OldAvgCostCalcType;
            InventorySetup.Modify();
        end;
    end;

    local procedure SetupItem(var Item: Record Item)
    begin
        with Item do begin
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Item);
            "Costing Method" := "Costing Method"::Average;
            "Unit Cost" := 99.99999;
            Insert();  // function which is tested later requires Item in table (GET method is called)
        end;
    end;

    local procedure SetupSKU(var SKU: Record "Stockkeeping Unit"; var Item: Record Item)
    begin
        with SKU do begin
            "Location Code" := LibraryUtility.GenerateRandomCode(FieldNo("Location Code"), DATABASE::"Stockkeeping Unit");
            "Item No." := Item."No.";
            "Variant Code" := '';
            "Unit Cost" := Item."Unit Cost";
            Insert();  // function which is tested later requires SKU in table due to MODIFY command
        end;
    end;

    local procedure SetupValueEntry(var ValueEntry: Record "Value Entry"; var SKU: Record "Stockkeeping Unit"; CostAmountActual: Decimal)
    begin
        with ValueEntry do begin
            if FindLast() then begin
                Init();
                "Entry No." += 1;
            end else
                "Entry No." := 1;
            "Item No." := SKU."Item No.";
            "Location Code" := SKU."Location Code";
            "Variant Code" := SKU."Variant Code";
            "Valuation Date" := WorkDate();
            "Item Ledger Entry Quantity" := 1;
            "Cost Amount (Actual)" := CostAmountActual;
            Insert();  // function which is tested later requires Value Entry in table
        end;
    end;

    local procedure VerifyUnitCostOfSKU(UnitCostOfSKU: Decimal; ItemUnitCost: Decimal; NewUnitCost: Decimal)
    begin
        if NewUnitCost <= 0 then
            Assert.AreEqual(ItemUnitCost, UnitCostOfSKU, '')
        else
            Assert.AreEqual(NewUnitCost, UnitCostOfSKU, '');
    end;
}

