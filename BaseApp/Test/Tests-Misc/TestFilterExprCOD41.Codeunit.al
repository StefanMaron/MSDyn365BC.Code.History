codeunit 139000 "Test Filter Expr. COD41"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Filter Tokens] [UT]
    end;

    var
        Assert: Codeunit "Assert";

    [Test]
    [Scope('OnPrem')]
    procedure MakeTextFilter1()
    var
        CommentLine: Record "Comment Line";
        i: Integer;
    begin
        // ME
        // USER
        // COMPANY
        CommentLine.SETRANGE("Table Name", CommentLine."Table Name"::Insurance);
        CommentLine.DeleteAll();
        CommentLine.Init();

        CommentLine."Table Name" := CommentLine."Table Name"::Insurance;
        i := i + 1;
        InsertCommentLine(CommentLine, FORMAT(i), '', 0D);
        i := i + 1;
        InsertCommentLine(CommentLine, FORMAT(i), USERID, 0D);
        i := i + 1;
        InsertCommentLine(CommentLine, FORMAT(i), COMPANYNAME, 0D);

        Assert.AreEqual(3, CommentLine.COUNT, 'Check before applying filters to CommentLine failed.');

        CommentLine.SETFILTER(Comment, '%1', USERID);
        Assert.AreEqual(1, CommentLine.COUNT, '%ME filter returned wrong number of records.');
        CommentLine.SETFILTER(Comment, '%1', USERID);
        Assert.AreEqual(1, CommentLine.COUNT, '%USER filter returned wrong number of records.');
        CommentLine.SETFILTER(Comment, '%1', COMPANYNAME);
        Assert.AreEqual(1, CommentLine.COUNT, '%COMPANY filter returned wrong number of records.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeTextFilter2()
    var
        Customer: Record "Customer";
        MyCustomer: Record "My Customer";
        i: Integer;
        NoPrefix: Code[10];
        ExpectedFilter: Text;
        NoOfElementsInFilter: Integer;
    begin
        // MYCUSTOMERS
        WITH Customer DO BEGIN
            NoPrefix := 'UTEST';
            SETFILTER("No.", 'UTEST' + '*');
            DeleteAll();
            MyCustomer.SETRANGE("User ID", USERID);
            MyCustomer.DeleteAll();
            ExpectedFilter := '';
            FOR i := 1 TO 100 DO BEGIN
                InsertCustomer(Customer, NoPrefix + FORMAT(100000 + i), 'Test Customer ' + FORMAT(i));
                IF i MOD 3 = 0 THEN BEGIN
                    InsertMyCustomer(Customer);
                    ExpectedFilter := AddToFilter(ExpectedFilter, "No.", NoOfElementsInFilter);
                END;
            END;
            Assert.AreEqual(100, COUNT, 'Check before applying filters to Customer failed.');

            SETFILTER("No.", '%MYCUSTOMERS');  // Raises a message
            Assert.IsTrue(COUNT <= MyCustomer.COUNT, '%MYCUSTOMERS filter returned too many records.');
            Assert.IsTrue(COUNT >= STRLEN(GETFILTER("No.")) DIV (STRLEN("No.") + 1), '%MYCUSTOMERS filter returned too few records.');
        END;
    end;

    [Test]
    [HandlerFunctions('ShowMessageHandler')]
    [Scope('OnPrem')]
    procedure MakeTextFilter3()
    var
        Vendor: Record "Vendor";
        MyVendor: Record "My Vendor";
        i: Integer;
        NoPrefix: Code[10];
        ExpectedFilter: Text;
        NoOfElementsInFilter: Integer;
    begin
        // MYVENDORS
        WITH Vendor DO BEGIN
            NoPrefix := 'UTEST';
            SETFILTER("No.", 'UTEST' + '*');
            DeleteAll();
            MyVendor.SETRANGE("User ID", USERID);
            MyVendor.DeleteAll();
            ExpectedFilter := '';
            FOR i := 1 TO 2100 DO BEGIN
                InsertVendor(Vendor, NoPrefix + FORMAT(100000 + i), 'Test Vendor ' + FORMAT(i));
                InsertMyVendor(Vendor);
                ExpectedFilter := AddToFilter(ExpectedFilter, "No.", NoOfElementsInFilter);
            END;
            Assert.AreEqual(2100, COUNT, 'Check before applying filters to Vendor failed.');

            SETFILTER("No.", '%MYVENDORS');
            Assert.IsTrue(COUNT <= MyVendor.COUNT, '%MYVENDORS filter returned too many records.');
        END;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeTextFilter4()
    var
        Item: Record "Item";
        MyItem: Record "My Item";
        i: Integer;
        NoPrefix: Code[10];
        ExpectedFilter: Text;
        NoOfElementsInFilter: Integer;
    begin
        // MYITEMS
        WITH Item DO BEGIN
            NoPrefix := 'UTEST';
            SETFILTER("No.", 'UTEST' + '*');
            DeleteAll();
            MyItem.SETRANGE("User ID", USERID);
            MyItem.DeleteAll();
            ExpectedFilter := '';
            FOR i := 1 TO 100 DO BEGIN
                InsertItem(Item, NoPrefix + FORMAT(100000 + i), 'Test Item ' + FORMAT(i));
                IF i MOD 3 = 0 THEN BEGIN
                    InsertMyItem(Item);
                    ExpectedFilter := AddToFilter(ExpectedFilter, "No.", NoOfElementsInFilter);
                END;
            END;
            Assert.AreEqual(100, COUNT, 'Check before applying filters to Item failed.');

            SETFILTER("No.", '%MYITEMS');
            Assert.IsTrue(COUNT <= MyItem.COUNT, '%MYITEMS filter returned too many records.');
            Assert.IsTrue(COUNT >= STRLEN(GETFILTER("No.")) DIV (STRLEN("No.") + 1), '%MYITEMS filter returned too few records.');
        END;
    end;

    local procedure InsertCommentLine(var CommentLine: Record "Comment Line"; No: Code[20]; Text: Text[80]; Date2: Date)
    begin
        WITH CommentLine DO BEGIN
            Init();
            "No." := No;
            Comment := Text;
            Date := Date2;
            Insert();
        END;
    end;

    local procedure InsertCustomer(var Customer: Record "Customer"; No: Code[20]; Name2: Text[50])
    begin
        WITH Customer DO BEGIN
            Init();
            "No." := No;
            Name := Name2;
            Insert();
        END;
    end;

    local procedure InsertMyCustomer(var Customer: Record "Customer")
    var
        MyCustomer: Record "My Customer";
    begin
        WITH MyCustomer DO BEGIN
            Init();
            "User ID" := USERID;
            "Customer No." := Customer."No.";
            Insert();
        END;
    end;

    local procedure InsertVendor(var Vendor: Record "Vendor"; No: Code[20]; Name2: Text[50])
    begin
        WITH Vendor DO BEGIN
            Init();
            "No." := No;
            Name := Name2;
            Insert();
        END;
    end;

    local procedure InsertMyVendor(var Vendor: Record "Vendor")
    var
        MyVendor: Record "My Vendor";
    begin
        WITH MyVendor DO BEGIN
            Init();
            "User ID" := USERID;
            "Vendor No." := Vendor."No.";
            Insert();
        END;
    end;

    local procedure InsertItem(var Item: Record "Item"; No: Code[20]; Description2: Text[50])
    begin
        WITH Item DO BEGIN
            Init();
            "No." := No;
            Description := Description2;
            Insert();
        END;
    end;

    local procedure InsertMyItem(var Item: Record "Item")
    var
        MyItem: Record "My Item";
    begin
        WITH MyItem DO BEGIN
            Init();
            "User ID" := USERID;
            "Item No." := Item."No.";
            Insert();
        END;
    end;

    local procedure AddToFilter(OldString: Text; NewNo: Text; var CurrElementNo: Integer): Text
    begin
        CurrElementNo += 1;
        IF OldString = '' THEN
            EXIT(NewNo);
        IF CurrElementNo > 2000 THEN
            EXIT(OldString);
        EXIT(OldString + '|' + NewNo);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShowMessageHandler(Msg: Text[1024])
    begin
    end;
}

