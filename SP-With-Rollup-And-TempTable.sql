CREATE PROCEDURE [dbo].[SPGetParialDeclarationOperationWeight]
	@DeclarationId uniqueidentifier,
	@ReturnWeight INT OUTPUT,
	@ReturnQuantity INT OUTPUT
AS
BEGIN
	
	SET NOCOUNT ON;

	--Gecici tablo olusturuluyor
	declare @TempData table
	(
		ProcessId   uniqueidentifier,
		DeclarationId   uniqueidentifier,
		DeclarationItemId   uniqueidentifier,
        Weight int,
		Quantity int,
		IsGrouped int
	)

	-->Cekilen veri gecici tabloya basiliyor
	INSERT  INTO @TempData (ProcessId, DeclarationId, DeclarationItemId, Weight, Quantity, IsGrouped)
	SELECT 
	--ROLLUP ile sorgu cekildigi icin rollup generated sutunlara null atadim, isim de verilebilir
	coalesce(ProcessId, NULL) AS Process,
	coalesce(DeclarationId, NULL) AS Declaration,
	coalesce(DeclarationItemId, NULL) AS DeclarationItem,
	--her process den bir tonaj alinacagi icin max diyerek secim yaptim
	(Max(Weight)) AS Weight,
	--tum operasyonlara ait adetler alinacagi icin sum ile adetler toplaniyor
	(Sum(Quantity)) AS Quantity,
	--rollup generated sutunlari belirtmek icin kullaniliyor (1 ise rollup generated 0 ise degil)
	GROUPING(DeclarationItemId) AS IsGrouped
	FROM Operation
	--deadlock olusmamasi icin with nolock
	WITH (NOLOCK)
	WHERE DeclarationId = @DeclarationId AND Type = 1 And Status <> 0
	--rollup ile alt toplam eklemek icin
	GROUP BY ROLLUP(ProcessId, DeclarationId, DeclarationItemId)
	--sadece rollup generated kayitlar gelsin
	HAVING DeclarationId = @DeclarationId AND GROUPING(DeclarationItemId) = 1
	ORDER BY ProcessId

	--output parameterlari doldur
	SET @ReturnWeight = (Select Sum(Weight) From @TempData)
	SET @ReturnQuantity = (Select Sum(Quantity) From @TempData)

END
