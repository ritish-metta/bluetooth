import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late AudioPlayer _audioPlayer;

  // Creating a playlist using ConcatenatingAudioSource
  final _playlist = ConcatenatingAudioSource(
    children: [
      AudioSource.uri(
        Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
        tag: MediaItem(
          id: '0',
          title: 'nature',
          artist: 'public domain',
          artUri: Uri.parse(
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSKn-X2ZRRr7DWK4gEnkQFFo_NSpS4dxoS-gg&s',
          ),
        ),
      ),
      AudioSource.uri(
        Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'),
        tag: MediaItem(
          id: '1',
          title: 'nature',
          artist: 'public domain',
          artUri: Uri.parse(
            'https://th.bing.com/th/id/OIP.5OK6HO5vQGYBAM3TutCtDgHaEK?w=296&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7',
          ),
        ),
      ),
      AudioSource.uri(
        Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'),
        tag: MediaItem(
          id: '2',
          title: 'nature',
          artist: 'public domain',
          artUri: Uri.parse(
            'https://th.bing.com/th/id/OIP.unrw5RnVrTYI5bgMqlkpugHaEo?w=275&h=180&c=7&r=0&o=5&dpr=1.3&pid=1.7',
          ),
        ),
      ),
    ],
  );

  // Stream to get PositionData
  Stream<PositionData> get _positionDataStream => Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setAudioSource(_playlist);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 25, 25),
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.teal[800],
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black54,
              Colors.black38,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<SequenceState?>(
              stream: _audioPlayer.sequenceStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state?.sequence.isEmpty ?? true) {
                  return const SizedBox();
                }
                final mediaItem = state!.currentSource!.tag as MediaItem;
                return MediaMetadata(
                  imageUrl: mediaItem.artUri.toString(),
                  title: mediaItem.title,
                  artist: mediaItem.artist ?? '',
                );
              },
            ),





            Controls(audioPlayer: _audioPlayer),
            const SizedBox(height: 20),
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;

                return ProgressBar(
                  barHeight: 8,
                  baseBarColor: Colors.blueAccent,
                  bufferedBarColor: Colors.black12,
                  progressBarColor: Colors.amberAccent,
                  thumbColor: Colors.black38,
                  timeLabelTextStyle: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                  progress: positionData?.position ?? Duration.zero,
                  buffered: positionData?.bufferedPosition ?? Duration.zero,
                  total: positionData?.duration ?? Duration.zero,
                  onSeek: _audioPlayer.seek,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MediaMetadata extends StatelessWidget {
  const MediaMetadata({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
  });

  final String imageUrl;
  final String title;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(2, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 300,
              width: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          artist,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class PositionData {
  const PositionData(
    this.position,
    this.bufferedPosition,
    this.duration,
  );

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}

class Controls extends StatelessWidget {
  const Controls({
    super.key,
    required this.audioPlayer,
  });

  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: audioPlayer.seekToPrevious, icon:const Icon(Icons.skip_previous_rounded),color:Colors.amberAccent ,
        iconSize: 50,
        ),

        StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
        
            if (!(playing ?? false)) {
              // If audio is not playing
              return IconButton(
                onPressed: audioPlayer.play,
                iconSize: 80,
                color: Colors.amberAccent,
                icon: const Icon(Icons.play_arrow_rounded),
              );
            } else if (processingState != ProcessingState.completed) {
              // If audio is playing
              return IconButton(
                onPressed: audioPlayer.pause,
                iconSize: 80,
                color: Colors.red,
                icon: const Icon(Icons.pause_rounded),
              );
            }
        
            // If audio playback is complete
            return const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 80,
            );
          },
        ),
         IconButton(onPressed: audioPlayer.seekToNext, icon:const Icon(Icons.skip_next_rounded),color:Colors.amberAccent ,
         iconSize: 50,
        ),
      ],
    );
  }
}
