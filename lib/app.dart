part of 'main.dart';

class StayNearApp extends StatefulWidget {
  const StayNearApp({super.key});
  @override
  State<StayNearApp> createState() => _StayNearAppState();
}

class _StayNearAppState extends State<StayNearApp> {
  UserRole role = UserRole.landlord;
  AppPage page = AppPage.auth;
  bool login = true;
  String? selectedListingId;
  AppPage listingOrigin = AppPage.boarderHome;
  int wizardStep = 0;
  Listing? ownerListing;
  UserProfile? registeredUser;
  UserProfile? activeUser;
  final demoListing = Listing(
    id: 'sample-jhes',
    title: 'Jhes BH',
    address: 'Poblacion Norte, Clarin, Bohol',
    price: 1200,
    image: roomImage,
    availableRooms: 5,
    totalRooms: 5,
    averageRating: 4.8,
    reviewCount: 24,
    amenities: ['WiFi', 'Air Conditioning', 'Study Desk', 'Shared Kitchen'],
    description: 'Student boarding house near the university in Clarin.',
  );
  late final ListingStore listingStore = ListingStore(
    samples: [
      demoListing,
      Listing(
        id: 'sample-zaframar',
        title: 'ZafraMar BH',
        address: 'Clarin, Bohol',
        price: 1200,
        image: alternateRoomImage,
        availableRooms: 2,
        totalRooms: 2,
        averageRating: 4.9,
        reviewCount: 18,
        amenities: ['WiFi', 'Study Desk', 'Laundry Area', 'Parking'],
      ),
      Listing(
        id: 'sample-annhath',
        title: "AnnHath's Boardinghouse",
        address: 'Pob. Centro, Clarin, Bohol',
        price: 1500,
        image: roomImage,
        availableRooms: 2,
        totalRooms: 2,
        averageRating: 4.7,
        reviewCount: 31,
        amenities: ['Air Conditioning', 'Private Bathroom', 'Furnished'],
      ),
    ],
  );

  @override
  void dispose() {
    listingStore.dispose();
    super.dispose();
  }

  void openListing(Listing listing) {
    setState(() {
      selectedListingId = listing.id;
      listingOrigin = page;
      page = AppPage.listing;
    });
  }

  void go(AppPage next) => setState(() => page = next);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: Builder(
        builder: (context) {
          late Widget body;
          switch (page) {
            case AppPage.auth:
              body = AuthPage(
                login: login,
                role: role,
                onRoleChanged: (r) => setState(() => role = r),
                onLoginChanged: (v) => setState(() => login = v),
                onRegister: (profile) {
                  setState(() {
                    registeredUser = profile;
                    activeUser = null;
                    role = profile.role;
                    login = true;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Account created successfully! '
                            'Please log in to continue.',
                          ),
                        ),
                      );
                  });
                },
                onLogin: (email, password, selectedRole) {
                  final user = registeredUser;
                  if (user == null ||
                      user.email.toLowerCase() != email.trim().toLowerCase() ||
                      user.password != password ||
                      user.role != selectedRole) {
                    return false;
                  }
                  setState(() {
                    activeUser = user;
                    role = user.role;
                  });
                  go(
                    user.role == UserRole.landlord
                        ? AppPage.landlordDashboard
                        : AppPage.boarderHome,
                  );
                  return true;
                },
              );
            case AppPage.landlordDashboard:
              body = LandlordDashboard(
                listing: ownerListing,
                onEdit: () => go(AppPage.editListing),
                onDelete: () => _confirmDelete(context),
                onAddRoom: () {
                  setState(() => wizardStep = 0);
                  go(AppPage.roomWizard);
                },
                onProfile: () => go(AppPage.profile),
              );
            case AppPage.editListing:
              body = EditListingPage(
                listing: ownerListing ?? demoListing,
                onBack: () => go(AppPage.landlordDashboard),
                onSave: (updated) {
                  setState(() => ownerListing = updated);
                  listingStore.upsert(updated);
                  go(AppPage.landlordDashboard);
                },
              );
            case AppPage.roomWizard:
              body = RoomWizard(
                step: wizardStep,
                onBack: () => go(AppPage.landlordDashboard),
                onProfile: () => go(AppPage.profile),
                onNext: () {
                  if (wizardStep < 3) {
                    setState(() => wizardStep++);
                  }
                },
                onPrevious: () => setState(() => wizardStep--),
                onPublish: (listing) {
                  setState(() {
                    wizardStep = 0;
                    ownerListing = listing;
                  });
                  listingStore.upsert(listing);
                  go(AppPage.landlordDashboard);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _publishedDialog(context);
                    }
                  });
                },
              );
            case AppPage.boarderHome:
              body = BoarderDashboard(
                store: listingStore,
                onListing: openListing,
                onFavorites: () => go(AppPage.favorites),
                onProfile: () => go(AppPage.profile),
              );
            case AppPage.favorites:
              body = FavoritesPage(
                store: listingStore,
                onListing: openListing,
                onHome: () => go(AppPage.boarderHome),
                onProfile: () => go(AppPage.profile),
              );
            case AppPage.listing:
              body = ListenableBuilder(
                listenable: listingStore,
                builder: (context, child) {
                  final selectedListing = listingStore.byId(selectedListingId);
                  return selectedListing == null
                      ? Column(
                          children: [
                            TopBar(
                              title: 'Property Details',
                              onBack: () => go(listingOrigin),
                            ),
                            const Expanded(
                              child: EmptyState(
                                icon: Icons.home_outlined,
                                title: 'Property no longer available',
                                text: 'Return to Search to find another property.',
                              ),
                            ),
                          ],
                        )
                      : ListingPage(
                          listing: selectedListing,
                          favorite: listingStore.isFavorite(selectedListing.id),
                          onFavorite: () =>
                              listingStore.toggleFavorite(selectedListing.id),
                          onBack: () => go(listingOrigin),
                        );
                },
              );
            case AppPage.profile:
              body = ProfilePage(
                user: activeUser,
                onEdit: () => go(AppPage.editProfile),
                onLogout: () => _logout(context),
                onHome: () => go(
                  role == UserRole.landlord
                      ? AppPage.landlordDashboard
                      : AppPage.boarderHome,
                ),
                onFavorites: () => go(AppPage.favorites),
              );
            case AppPage.editProfile:
              body = EditProfilePage(
                role: role,
                onBack: () => go(AppPage.profile),
                onSave: () => _confirmProfileSave(context),
              );
          }
          return ScreenFrame(child: body);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 19, 17, 17),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Delete Listing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to delete this listing?\n'
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: muted),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 26,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F2F4),
                          foregroundColor: ink,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 26,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          final deletedListing = ownerListing;
                          if (deletedListing != null) {
                            listingStore.remove(deletedListing.id);
                          }
                          setState(() => ownerListing = null);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Listing deleted')),
                          );
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _publishedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 32, 26, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: paleBlue,
                child: Icon(Icons.check_rounded, color: blue, size: 46),
              ),
              const SizedBox(height: 24),
              const Text(
                'Listing Published\nsuccessfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF495064),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFFF44348)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      page = AppPage.auth;
                      login = true;
                      activeUser = null;
                    });
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Yes', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmProfileSave(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to save?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF495064),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    go(AppPage.profile);
                  },
                  child: const Text('Yes', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
