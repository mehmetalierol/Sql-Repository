CREATE PROCEDURE [dbo].[LiscontCreateTransaction]
       -- Add the parameters for the stored procedure here
       @XmlSource xml
AS
       SET NOCOUNT ON; 
       declare @ContainerId uniqueidentifier
       declare @LinerId uniqueidentifier
	   declare @TruckId uniqueidentifier
	   declare @TrailerId uniqueidentifier
	   declare @ContainerVisitId uniqueidentifier
       declare @TransCount int
	   declare @ContainerNo nvarchar(50)
       declare @Payload nvarchar(50)
       declare @Tare nvarchar(50)
       declare @Type nvarchar(50)
	   declare @Category nvarchar(50)
       declare @LicensePlate nvarchar(50)
	   declare @TrailerPlate nvarchar(50)
       declare @Pod nvarchar(50)
       declare @Pol nvarchar(50)
       declare @Podname nvarchar(50)
	   declare @Position nvarchar(50)
       declare @Polname nvarchar(50)
       declare @VesselVisit nvarchar(50)
       declare @Destination nvarchar(50)
       declare @FKind nvarchar(50)
       declare @TState nvarchar(50)
       declare @Flex1 nvarchar(50)
       declare @IsApproved bit
       declare @Flex2 nvarchar(50)
       declare @Liner nvarchar(50)
	   declare @TimeLastMove nvarchar(50)
	   declare @HandlingRemark nvarchar(250) = ''

       begin try 
			 
			 SELECT @ContainerNo = @XmlSource.value('(/argo/unit/@id)[1]', 'nvarchar(20)')
			 SELECT @ContainerId = Id FROM Containers WHERE ContainerNumber = @ContainerNo
			 if(@ContainerId is NULL)
             begin
					set @ContainerId = NEWID()
					SELECT @Type = @XmlSource.value('(/argo/unit/equipment/@type)[1]', 'nvarchar(20)')
					SELECT @Payload = @XmlSource.value('(/argo/unit/equipment/physical/@tare-weight-kg)[1]', 'nvarchar(20)')
					SELECT @Tare = @XmlSource.value('(/argo/unit/equipment/restrictions/@safe-weight-kg)[1]', 'nvarchar(20)')
                    Insert Into Containers(Id,ContainerNumber,Payload,Tare,Type) values (@ContainerId,@ContainerNo,@Payload,@Tare,@Type);
             end

			 SELECT @Liner = @XmlSource.value('(/argo/unit/@line)[1]', 'nvarchar(20)')
			 SELECT @LinerId = Id FROM Liners WHERE Name = @liner
			 if(@LinerId is NULL)
             begin
					set @LinerId = NEWID()
                    Insert Into Liners (Id,Name) values (@LinerId,@Liner);
             end

			 SELECT @LicensePlate = @XmlSource.value('(/argo/unit/position/@location)[1]', 'nvarchar(30)')
			 SELECT @Position = @XmlSource.value('(/argo/unit/position/@loc-type)[1]', 'nvarchar(30)')
			 
			 if(@LicensePlate is not NULL and @Position is not null)
			 begin
					if(@Position = 'TRUCK')
					begin
						SELECT @TruckId = Id FROM Trucks WHERE LicensePlate = @LicensePlate
						if(@TruckId is NULL)
						begin
							SET @TruckId = NEWID()
							Insert Into Trucks(Id,LicensePlate) values (@TruckId,@LicensePlate);
						end
					end
			 end

			 Select @TransCount = Count(*) From ContainersVisits Where ContainerId = @ContainerId And  CreatedDate > DATEADD(hour, -2, getdate())

			 if(@TransCount = 0)
             begin
					set @ContainerVisitId = NEWID()
					SELECT @Category = @XmlSource.value('(/argo/unit/@category)[1]', 'nvarchar(30)')
					SELECT @TState = @XmlSource.value('(/argo/unit/@transit-state)[1]', 'nvarchar(30)')
					SELECT @FKind = @XmlSource.value('(/argo/unit/@freight-kind)[1]', 'nvarchar(30)')
					SELECT @TimeLastMove = @XmlSource.value('(/argo/unit/timestamps/@time-last-move)[1]', 'nvarchar(30)')
					SELECT @VesselVisit = @XmlSource.value('(/argo/unit/routing/carrier/@id)[3]', 'nvarchar(30)')
					SELECT @Pod = @XmlSource.value('(/argo/unit/routing/@pod-1)[1]', 'nvarchar(30)')
					SELECT @Podname = @XmlSource.value('(/argo/unit/routing/@pod-1-name)[1]', 'nvarchar(30)')
					SELECT @Destination = @XmlSource.value('(/argo/unit/routing/@destination)[1]', 'nvarchar(30)')
					SELECT @Flex1 = @XmlSource.value('(/argo/unit/ufv-flex/@ufv-flex-3)[1]', 'nvarchar(30)')
					SELECT @Flex2 = @XmlSource.value('(/argo/unit/ufv-flex/@ufv-flex-3)[1]', 'nvarchar(30)')

					INSERT INTO [dbo].[ContainersVisits] ([Id],[ContainerId],[LineId],[TerminalId],[Category],[TransitState],[FrightKind],[Position],[Location],[TimeLastMove],[Carrier],[Pod],[PodName],[Destination],[Flex1],[Flex2])
					VALUES 
					(@ContainerVisitId,@ContainerId,@LinerId,'fed5eab0-bf65-4051-9e6f-cfe432c332ef',@Category,@TState,@FKind,@Position,@LicensePlate,@TimeLastMove,@VesselVisit,@Pod,@Podname,@Destination,@Flex1,@Flex2)
			 end

		end try

		begin catch
             insert into xmltest (result) values (ERROR_MESSAGE())
       end catch 