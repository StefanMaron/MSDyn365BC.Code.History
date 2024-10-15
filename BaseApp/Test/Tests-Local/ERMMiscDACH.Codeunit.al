codeunit 142087 "ERM Misc. DACH"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInvOrderLineProductGroupCodeFieldIsObsolete()
    begin
        // [SCENARIO 297397] Field Product Group Code has ObsoleteState=Pending in Phys Inventory Order Line table

        VerifyFieldIsObsoleteStatePending(5005351, 5707);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPhysInvOrderLineProductGroupCodeFieldIsObsolete()
    begin
        // [SCENARIO 297397] Field Product Group Code has ObsoleteState=Pending in Posted Phys. Invt. Order Line table

        VerifyFieldIsObsoleteStatePending(5005355, 5707);
    end;

    local procedure VerifyFieldIsObsoleteStatePending(TableNo: Integer; FieldNo: Integer)
    var
        "Field": Record "Field";
    begin
        Field.Get(TableNo, FieldNo);
        Field.TestField(ObsoleteState, Field.ObsoleteState::Pending);
    end;
}

